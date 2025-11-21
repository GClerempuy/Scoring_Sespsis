#!/usr/bin/env Rscript

# Script de scoring et clustering basé sur les coefficients de régression logistique
# Usage: Rscript Scoring_UVSQ_cluster.R -i Data_metadata.csv -c Coefficients_clust.csv -o TEST_clust_scoring.csv -v

library(optparse)

# ============================================================================
# DÉFINITION DES BORNES ET SEUILS
# ============================================================================
bornes_intervalles <- list(
  borne_min_bas = 0.390448,
  borne_max_bas = 0.7629905,
  borne_min_haut = 0.7686798,
  borne_max_haut = 0.9766953,
  n_patients_bas = 49,
  n_patients_haut = 30,
  seuil_utilise = 0.7658351
)

seuil_optimal <- 0.7658351

# ============================================================================
# FONCTION DE NORMALISATION
# ============================================================================
normaliser_score <- function(score_brut, bornes_intervalles, seuil_optimal) {
  # Transformation du score brut en probabilité
  proba <- 1 / (1 + exp(-score_brut))
  
  # Détermination de l'intervalle basé sur la probabilité
  if (proba < seuil_optimal) {
    # Intervalle bas [0, 0.5[
    min_intervalle <- bornes_intervalles$borne_min_bas
    max_intervalle <- bornes_intervalles$borne_max_bas
    
    # Vérification que les bornes existent
    if (is.na(min_intervalle) || is.na(max_intervalle)) {
      warning("Bornes de l'intervalle bas non disponibles")
      return(NA)
    }
    
    # Normalisation dans [0, 0.5[
    if (max_intervalle == min_intervalle) {
      proba_normalisee <- 0.25  # Valeur médiane si pas de variation
    } else {
      proba_normalisee <- ((proba - min_intervalle) / (max_intervalle - min_intervalle)) * 0.5
    }
    
  } else {
    # Intervalle haut [0.5, 1]
    min_intervalle <- bornes_intervalles$borne_min_haut
    max_intervalle <- bornes_intervalles$borne_max_haut
    
    # Vérification que les bornes existent
    if (is.na(min_intervalle) || is.na(max_intervalle)) {
      warning("Bornes de l'intervalle haut non disponibles")
      return(NA)
    }
    
    # Normalisation dans [0.5, 1]
    if (max_intervalle == min_intervalle) {
      proba_normalisee <- 0.75  # Valeur médiane si pas de variation
    } else {
      proba_normalisee <- 0.5 + ((proba - min_intervalle) / (max_intervalle - min_intervalle)) * 0.5
    }
  }
  
  # S'assurer que la valeur reste dans [0, 1]
  proba_normalisee <- max(0, min(1, proba_normalisee))
  
  return(proba_normalisee)
}

# ============================================================================
# DÉFINITION DES ARGUMENTS DE LIGNE DE COMMANDE
# ============================================================================
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL, 
              help="Fichier d'entrée avec patients en lignes et features en colonnes", metavar="character"),
  make_option(c("-c", "--coefficients"), type="character", default=NULL,
              help="Fichier des coefficients du modèle", metavar="character"),
  make_option(c("-o", "--output"), type="character", default=NULL,
              help="Fichier de sortie avec scores et clusters", metavar="character"),
  make_option(c("-v", "--verbose"), action="store_true", default=FALSE,
              help="Mode verbose pour détailler le processus"),
  make_option(c("-t", "--truth_column"), type="character", default=NULL,
              help="Nom de la colonne contenant les clusters réels (pour validation)", metavar="character")
)

# Parse des arguments
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# ============================================================================
# FONCTION POUR AFFICHER LES MESSAGES EN MODE VERBOSE
# ============================================================================
verbose_print <- function(message, verbose=FALSE) {
  if (verbose) {
    cat(paste0("[INFO] ", Sys.time(), " - ", message, "\n"))
  }
}

# ============================================================================
# VÉRIFICATION DES ARGUMENTS OBLIGATOIRES
# ============================================================================
if (is.null(opt$input) || is.null(opt$coefficients) || is.null(opt$output)) {
  print_help(opt_parser)
  stop("Les arguments -i, -c et -o sont obligatoires.", call.=FALSE)
}

verbose_print("Début du processus de scoring", opt$verbose)

# ============================================================================
# LECTURE DU FICHIER DES COEFFICIENTS
# ============================================================================
verbose_print(paste("Lecture du fichier coefficients:", opt$coefficients), opt$verbose)
tryCatch({
  coefficients <- read.csv(opt$coefficients, stringsAsFactors = FALSE)
}, error = function(e) {
  stop(paste("Erreur lors de la lecture du fichier coefficients:", e$message))
})

verbose_print(paste("Nombre de coefficients lus:", nrow(coefficients)), opt$verbose)

# Extraction des features sélectionnées et leurs coefficients
selected_features <- coefficients[coefficients$Type == "Selected", ]
verbose_print(paste("Nombre de features sélectionnées:", nrow(selected_features)), opt$verbose)

if (nrow(selected_features) == 0) {
  stop("Aucune feature sélectionnée trouvée dans le fichier coefficients.")
}

# ============================================================================
# LECTURE DU FICHIER DE DONNÉES
# ============================================================================
verbose_print(paste("Lecture du fichier de données:", opt$input), opt$verbose)
tryCatch({
  data <- read.csv(opt$input, stringsAsFactors = FALSE, row.names = 1)
}, error = function(e) {
  stop(paste("Erreur lors de la lecture du fichier de données:", e$message))
})

verbose_print(paste("Dimensions des données:", nrow(data), "patients x", ncol(data), "features"), opt$verbose)

# ============================================================================
# VÉRIFICATION DE LA PRÉSENCE DES FEATURES REQUISES
# ============================================================================
required_features <- selected_features$Feature
missing_features <- setdiff(required_features, colnames(data))

if (length(missing_features) > 0) {
  error_msg <- paste("ERREUR: Les features suivantes sont manquantes dans le fichier de données:",
                     paste(missing_features, collapse = ", "))
  cat(error_msg, "\n")
  stop(error_msg)
}

verbose_print("Toutes les features requises sont présentes", opt$verbose)

# ============================================================================
# CALCUL DES SCORES POUR CHAQUE PATIENT
# ============================================================================
verbose_print("Calcul des scores pour chaque patient", opt$verbose)

# Extraction des données pour les features sélectionnées
selected_data <- data[, required_features, drop = FALSE]

# Calcul du score linéaire (somme pondérée) - SCORE BRUT
raw_scores <- as.matrix(selected_data) %*% selected_features$Coefficient
raw_scores <- as.numeric(raw_scores)

verbose_print(paste("Scores bruts calculés - Min:", round(min(raw_scores), 4), 
                   "Max:", round(max(raw_scores), 4),
                   "Moyenne:", round(mean(raw_scores), 4)), opt$verbose)

# ============================================================================
# CALCUL DES PROBABILITÉS BRUTES (TRANSFORMATION LOGISTIQUE)
# ============================================================================
verbose_print("Calcul des probabilités brutes (transformation logistique)", opt$verbose)
proba_brute <- 1 / (1 + exp(-raw_scores))

verbose_print(paste("Probabilités brutes - Min:", round(min(proba_brute), 4), 
                   "Max:", round(max(proba_brute), 4),
                   "Moyenne:", round(mean(proba_brute), 4)), opt$verbose)

# ============================================================================
# ATTRIBUTION DES CLUSTERS BASÉE SUR LA PROBABILITÉ BRUTE
# ============================================================================
verbose_print(paste("Attribution des clusters avec seuil optimal:", round(seuil_optimal, 4)), opt$verbose)

# Cluster 1 si proba < seuil, Cluster 2 sinon
clusters <- ifelse(proba_brute < seuil_optimal, 1, 2)

verbose_print(paste("Distribution des clusters - Cluster 1:", sum(clusters == 1),
                   "Cluster 2:", sum(clusters == 2)), opt$verbose)

# ============================================================================
# NORMALISATION DES SCORES AVEC LA FONCTION PERSONNALISÉE
# ============================================================================
verbose_print("Normalisation des scores avec bornes d'intervalles", opt$verbose)

proba_normalisee <- sapply(raw_scores, function(score) {
  normaliser_score(score, bornes_intervalles, seuil_optimal)
})

verbose_print(paste("Probabilités normalisées - Min:", round(min(proba_normalisee, na.rm = TRUE), 4), 
                   "Max:", round(max(proba_normalisee, na.rm = TRUE), 4),
                   "Moyenne:", round(mean(proba_normalisee, na.rm = TRUE), 4)), opt$verbose)

# Vérifier s'il y a des valeurs NA
if (any(is.na(proba_normalisee))) {
  warning(paste("Attention:", sum(is.na(proba_normalisee)), 
                "valeurs NA détectées dans les probabilités normalisées"))
}

# ============================================================================
# CRÉATION DU DATAFRAME DE SORTIE
# ============================================================================
output_data <- data.frame(
  row.names = rownames(data),
  data,  # Données originales
  Score_Brut = round(raw_scores, 6),
  Proba_Brute = round(proba_brute, 6),
  Proba_Normalisee = round(proba_normalisee, 6),
  Cluster_Predit = clusters,
  stringsAsFactors = FALSE
)

# ============================================================================
# CALCUL DES MÉTRIQUES DE PERFORMANCE (SI COLONNE DE VÉRITÉ FOURNIE)
# ============================================================================
if (!is.null(opt$truth_column) && opt$truth_column %in% colnames(data)) {
  verbose_print(paste("Calcul des métriques de performance avec colonne:", opt$truth_column), opt$verbose)
  
  # Vérifier que la bibliothèque pROC est disponible
  if (!requireNamespace("pROC", quietly = TRUE)) {
    warning("Package 'pROC' non disponible. Installation automatique...")
    install.packages("pROC", repos = "https://cloud.r-project.org/")
  }
  library(pROC)
  
  verite <- data[[opt$truth_column]]
  
  # Convertir en binaire si nécessaire (1,2 -> 0,1)
  if (all(verite %in% c(1, 2))) {
    verite_binaire <- ifelse(verite == 2, 1, 0)
    
    # Calcul ROC et AUC avec Proba_Brute
    roc_brute <- roc(verite_binaire, proba_brute, quiet = TRUE)
    auc_brute <- auc(roc_brute)
    
    # Calcul ROC et AUC avec Proba_Normalisee
    roc_norm <- roc(verite_binaire, proba_normalisee, quiet = TRUE)
    auc_norm <- auc(roc_norm)
    
    # Matrice de confusion
    confusion_matrix <- table(Verite = verite, Prediction = clusters)
    
    # Métriques de performance
    accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
    
    # Calcul de la sensibilité et spécificité
    if (nrow(confusion_matrix) == 2 && ncol(confusion_matrix) == 2) {
      sensitivity <- confusion_matrix[2, 2] / sum(confusion_matrix[2, ])
      specificity <- confusion_matrix[1, 1] / sum(confusion_matrix[1, ])
    } else {
      sensitivity <- NA
      specificity <- NA
    }
    
    # Affichage des résultats
    cat("\n============================================\n")
    cat("RÉSULTATS DE LA PRÉDICTION\n")
    cat("============================================\n\n")
    
    cat("📊 AUC (Probabilité Brute):", round(auc_brute, 4), "\n")
    cat("📊 AUC (Probabilité Normalisée):", round(auc_norm, 4), "\n")
    cat("🎯 Accuracy:", round(accuracy * 100, 2), "%\n")
    
    if (!is.na(sensitivity)) {
      cat("🔍 Sensibilité (Cluster 2):", round(sensitivity * 100, 2), "%\n")
      cat("🔍 Spécificité (Cluster 1):", round(specificity * 100, 2), "%\n")
    }
    
    cat("\nMatrice de confusion:\n")
    print(confusion_matrix)
    cat("\n")
    
    # Statistiques par cluster
    cat("Statistiques par cluster:\n")
    cat("------------------------\n")
    for (clust in sort(unique(verite))) {
      subset_clust <- output_data[verite == clust, ]
      cat(sprintf("Cluster %d (n=%d):\n", clust, nrow(subset_clust)))
      cat(sprintf("  Score brut: %.4f ± %.4f [%.4f, %.4f]\n", 
                 mean(subset_clust$Score_Brut), 
                 sd(subset_clust$Score_Brut),
                 min(subset_clust$Score_Brut),
                 max(subset_clust$Score_Brut)))
      cat(sprintf("  Proba brute: %.4f ± %.4f [%.4f, %.4f]\n", 
                 mean(subset_clust$Proba_Brute), 
                 sd(subset_clust$Proba_Brute),
                 min(subset_clust$Proba_Brute),
                 max(subset_clust$Proba_Brute)))
      cat(sprintf("  Proba normalisée: %.4f ± %.4f [%.4f, %.4f]\n\n", 
                 mean(subset_clust$Proba_Normalisee, na.rm = TRUE), 
                 sd(subset_clust$Proba_Normalisee, na.rm = TRUE),
                 min(subset_clust$Proba_Normalisee, na.rm = TRUE),
                 max(subset_clust$Proba_Normalisee, na.rm = TRUE)))
    }
  } else {
    warning("Les valeurs de la colonne de vérité ne sont pas 1 et 2")
  }
}

# ============================================================================
# SAUVEGARDE DES RÉSULTATS
# ============================================================================
verbose_print(paste("Sauvegarde des résultats dans:", opt$output), opt$verbose)
tryCatch({
  write.csv(output_data, opt$output, row.names = TRUE, quote = FALSE)
}, error = function(e) {
  stop(paste("Erreur lors de l'écriture du fichier de sortie:", e$message))
})

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================
verbose_print("=== RÉSUMÉ FINAL ===", opt$verbose)
verbose_print(paste("Patients traités:", nrow(output_data)), opt$verbose)
verbose_print(paste("Features utilisées:", length(required_features)), opt$verbose)
verbose_print(paste("Score brut moyen:", round(mean(raw_scores), 4)), opt$verbose)
verbose_print(paste("Probabilité brute moyenne:", round(mean(proba_brute), 4)), opt$verbose)
verbose_print(paste("Probabilité normalisée moyenne:", round(mean(proba_normalisee, na.rm = TRUE), 4)), opt$verbose)
verbose_print(paste("Écart-type des scores bruts:", round(sd(raw_scores), 4)), opt$verbose)
verbose_print(paste("Seuil optimal utilisé:", round(seuil_optimal, 4)), opt$verbose)
verbose_print(paste("Fichier de sortie créé:", opt$output), opt$verbose)

cat("\n✅ Processus terminé avec succès!\n")
