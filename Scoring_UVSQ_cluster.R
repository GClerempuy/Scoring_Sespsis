#!/usr/bin/env Rscript

# Script de scoring et clustering basé sur les coefficients de régression logistique
# Auteur: Script généré pour UVSQ
# Usage: Rscript Scoring_UVSQ_cluster.R -i Data_metadata.csv -c Coefficients_clust.csv -o TEST_clust_scoring.csv -v

library(optparse)

# Définition des arguments de ligne de commande
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL, 
              help="Fichier d'entrée avec patients en lignes et features en colonnes", metavar="character"),
  make_option(c("-c", "--coefficients"), type="character", default=NULL,
              help="Fichier des coefficients du modèle", metavar="character"),
  make_option(c("-o", "--output"), type="character", default=NULL,
              help="Fichier de sortie avec scores et clusters", metavar="character"),
  make_option(c("-v", "--verbose"), action="store_true", default=FALSE,
              help="Mode verbose pour détailler le processus")
)

# Parse des arguments
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Fonction pour afficher les messages en mode verbose
verbose_print <- function(message, verbose=FALSE) {
  if (verbose) {
    cat(paste0("[INFO] ", Sys.time(), " - ", message, "\n"))
  }
}

# Vérification des arguments obligatoires
if (is.null(opt$input) || is.null(opt$coefficients) || is.null(opt$output)) {
  print_help(opt_parser)
  stop("Les arguments -i, -c et -o sont obligatoires.", call.=FALSE)
}

verbose_print("Début du processus de scoring", opt$verbose)

# Lecture du fichier des coefficients
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

# Lecture du fichier de données
verbose_print(paste("Lecture du fichier de données:", opt$input), opt$verbose)
tryCatch({
  data <- read.csv(opt$input, stringsAsFactors = FALSE, row.names = 1)
}, error = function(e) {
  stop(paste("Erreur lors de la lecture du fichier de données:", e$message))
})

verbose_print(paste("Dimensions des données:", nrow(data), "patients x", ncol(data), "features"), opt$verbose)

# Vérification de la présence des features requises
required_features <- selected_features$Feature
missing_features <- setdiff(required_features, colnames(data))

if (length(missing_features) > 0) {
  error_msg <- paste("ERREUR: Les features suivantes sont manquantes dans le fichier de données:",
                     paste(missing_features, collapse = ", "))
  cat(error_msg, "\n")
  stop(error_msg)
}

verbose_print("Toutes les features requises sont présentes", opt$verbose)

# Calcul du score pour chaque patient
verbose_print("Calcul des scores pour chaque patient", opt$verbose)

# Extraction des données pour les features sélectionnées
selected_data <- data[, required_features, drop = FALSE]

# Calcul du score linéaire (somme pondérée) - SCORE BRUT
raw_scores <- as.matrix(selected_data) %*% selected_features$Coefficient
raw_scores <- as.numeric(raw_scores)

verbose_print(paste("Scores bruts calculés - Min:", round(min(raw_scores), 4), 
                   "Max:", round(max(raw_scores), 4)), opt$verbose)

# Attribution des clusters basée sur le seuil optimal LASSO
# Le seuil 31.84 est sur l'échelle 0-100, donc nous le convertissons en proportion
threshold_proportion <- 31.8376219080996 / 100  # = 0.3184
threshold_raw <- min(raw_scores) + threshold_proportion * (max(raw_scores) - min(raw_scores))
verbose_print(paste("Seuil LASSO converti pour scores bruts:", round(threshold_raw, 4)), opt$verbose)

clusters <- ifelse(raw_scores < threshold_raw, 1, 2)

verbose_print(paste("Distribution des clusters - Cluster 1:", sum(clusters == 1),
                   "Cluster 2:", sum(clusters == 2)), opt$verbose)

# Normalisation des scores APRÈS assignation des clusters
min_score <- min(raw_scores)
max_score <- max(raw_scores)
normalized_scores <- (raw_scores - min_score) / (max_score - min_score)

verbose_print(paste("Scores normalisés - Min:", round(min(normalized_scores), 4), 
                   "Max:", round(max(normalized_scores), 4)), opt$verbose)

# Création du dataframe de sortie
output_data <- data.frame(
  row.names = rownames(data),
  data,  # Données originales
  Score_Raw = round(raw_scores, 6),
  Score = round(normalized_scores, 6),
  Cluster = clusters,
  stringsAsFactors = FALSE
)

# Sauvegarde des résultats
verbose_print(paste("Sauvegarde des résultats dans:", opt$output), opt$verbose)
tryCatch({
  write.csv(output_data, opt$output, row.names = TRUE, quote = FALSE)
}, error = function(e) {
  stop(paste("Erreur lors de l'écriture du fichier de sortie:", e$message))
})

# Résumé final
verbose_print("=== RÉSUMÉ FINAL ===", opt$verbose)
verbose_print(paste("Patients traités:", nrow(output_data)), opt$verbose)
verbose_print(paste("Features utilisées:", length(required_features)), opt$verbose)
verbose_print(paste("Score brut moyen:", round(mean(raw_scores), 4)), opt$verbose)
verbose_print(paste("Score normalisé moyen:", round(mean(normalized_scores), 4)), opt$verbose)
verbose_print(paste("Écart-type des scores bruts:", round(sd(raw_scores), 4)), opt$verbose)
verbose_print(paste("Fichier de sortie créé:", opt$output), opt$verbose)

cat("Processus terminé avec succès!\n")