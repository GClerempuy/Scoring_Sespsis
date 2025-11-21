# ============================================================================
# NORMALISATION DES SCORES DE PRÉDICTION
# ============================================================================

# Fonction: Normalisation d'un score brut ----------------------------------

bornes_intervalles <- list(
  borne_min_bas = 0.390448,
  borne_max_bas = 0.4563763,
  borne_min_haut = 0.4737034,
  borne_max_haut = 0.9766953,
  n_patients_bas = 8,
  n_patients_haut = 71,
  seuil_utilise = 0.7658351
)

seuil_optimal <- 0.7658351
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
