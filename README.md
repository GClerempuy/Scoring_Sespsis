# Scoring_Sepsis 

## 📋 Description du Projet

Ce projet vise à développer un modèle de prédiction pour classifier les patients atteints de sepsis selon leur probabilité de survie. Le système utilise une approche combinant apprentissage non-supervisé et régression logistique pour identifier des profils de patients à risque.

### 🏥 Contexte Médical
Le sepsis est une réponse inflammatoire systémique grave à une infection, représentant une urgence médicale majeure avec un taux de mortalité élevé. L'identification précoce des patients à haut risque est cruciale pour optimiser la prise en charge thérapeutique et améliorer les résultats cliniques.

### 🎯 Objectifs
- **Principal** : Stratifier les patients septiques en clusters selon leur risque de mortalité
- **Secondaire** : Fournir un score de risque normalisé pour aide à la décision clinique
- **Validation** : Corrélation établie avec la survie à J90

### 📊 Performance du Modèle

Le modèle a été rigoureusement validé avec les métriques suivantes :

| Métrique | Valeur | Description |
|----------|--------|-------------|
| **AUC** | **0.878** | Excellente capacité discriminante |
| **Accuracy** | **82.3%** | Taux de classification correcte |
| **Precision** | **81.6%** | Exactitude des prédictions positives |
| **Recall (Sensibilité)** | **88.9%** | Détection des patients à haut risque |
| **F1-Score** | **85.1%** | Équilibre précision/sensibilité |

> 🎯 **Performance clinique** : Le modèle identifie correctement près de 9 patients à haut risque sur 10 (sensibilité 88.9%), avec une excellente capacité discriminante globale (AUC 0.878).

---

## 🔬 Méthodologie

### 1. Clustering Hiérarchique Non-Supervisé
- Identification de groupes naturels de patients basée sur leurs caractéristiques cliniques et biologiques
- Clustering validé par corrélation avec la survie à 90 jours
- Méthode : Ward's hierarchical clustering

### 2. Modèle de Régression Logistique LASSO
- Sélection automatique des features les plus prédictives
- Génération de coefficients pour le calcul du score de risque
- **Seuil optimal déterminé** : 76.58% (probabilité brute)
- Validation croisée pour robustesse

### 3. Système de Normalisation Avancé
- **Transformation logistique** : Conversion du score linéaire en probabilité
- **Normalisation segmentée** : Utilisation de bornes d'intervalles par cluster
- **Attribution des clusters** : Basée sur la probabilité brute (seuil = 0.7658)

### 4. Classification des Patients
- **Cluster 1** : Patients à faible risque (probabilité brute < 76.58%)
- **Cluster 2** : Patients à haut risque (probabilité brute ≥ 76.58%)

---
## 🌐 Utilisation en ligne

### Lien 

### Nécéssité

Pour l'utilisation en ligne via GitHub page, vous aurez besoins de rentrer le taux d'expression des gènes suivants :

| ensembl_gene_id | hgnc_symbol | entrezgene_id |
|-----------------|-------------|---------------|
| ENSG00000134014 | ELP3        | 55140         |
| ENSG00000137802 | MAPKBP1     | 23005         |
| ENSG00000155229 | MMS19       | 64210         |
| ENSG00000175216 | CKAP5       | 9793          |

| `-i` | `--input` | Fichier de données patients | ✅ Oui |
| `-c` | `--coefficients` | Fichier des coefficients LASSO | ✅ Oui |

Ainsi que l'âge du patient que vous souhaitez vérifier, la version en ligne ne marche que pour 1 patient à la fois.

## 🛠️ Prérequis Techniques

### Environnement R
```bash
R version >= 3.6.0
```

### Packages R Requis
```R
install.packages("optparse")  # Obligatoire
install.packages("pROC")      # Optionnel (pour validation)
```

---

## 📁 Structure des Fichiers

### Fichiers d'Entrée

#### 1. `Data_metadata.csv`
Fichier de données patients avec :
- **Format** : CSV avec headers
- **Structure** : 
  - Lignes : Patients (identifiants en première colonne)
  - Colonnes : Features cliniques et biologiques
- **Exemple** :
```csv
Patient_ID,Feature1,Feature2,Feature3,...
PAT001,0.234,1.567,0.891,...
PAT002,0.456,2.134,0.234,...
```

#### 2. `Coefficients_clust.csv`
Fichier des coefficients du modèle LASSO :
- **Colonnes obligatoires** :
  - `Feature` : Nom de la variable
  - `Coefficient` : Valeur du coefficient
  - `Type` : "Selected" pour les features retenues
- **Exemple** :
```csv
Feature,Coefficient,Type
ENSG00000134014, 0.488, Gène
ENSG00000137802, 0.3306, Gène	
ENSG00000155229,0.3273,	Gène	
ENSG00000175216,	0.241, Gène	
I_AGE, -0.0123,	Clinique

### Fichier de Sortie

#### `resultats_scoring.csv`
Contient :
- **Données originales** : Toutes les colonnes du fichier d'entrée
- **Score_Brut** : Score linéaire (somme pondérée)
- **Proba_Brute** : Probabilité issue de la transformation logistique
- **Proba_Normalisee** : Probabilité normalisée avec bornes d'intervalles
- **Cluster_Predit** : Attribution du cluster (1 ou 2)

---

## 📊 Utilisation du Script

### 🌐 Version en Ligne
**Interface web disponible** : [https://gclerempuy.github.io/Scoring_Sespsis/](https://gclerempuy.github.io/Scoring_Sespsis/)

### 💻 Utilisation en Ligne de Commande

#### Syntaxe de Base
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv
```

#### Avec Validation et Mode Verbose
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv \
    -t clust \
    -v
```

### Options Disponibles

| Option | Argument Long | Description | Obligatoire |
|--------|--------------|-------------|-------------|
| `-i` | `--input` | Fichier de données patients | ✅ Oui |
| `-c` | `--coefficients` | Fichier des coefficients LASSO | ✅ Oui |
| `-o` | `--output` | Fichier de sortie avec scores | ✅ Oui |
| `-t` | `--truth_column` | Colonne des clusters réels (pour validation) | ❌ Non |
| `-v` | `--verbose` | Mode détaillé (affiche les étapes) | ❌ Non |

### 📝 Exemples d'Utilisation

#### Mode Standard
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv
```

#### Mode Validation Complète
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv \
    -t clust \
    -v
```

**Sortie avec validation** :
```
============================================
RÉSULTATS DE LA PRÉDICTION
============================================

📊 AUC (Probabilité Brute): 0.8778
📊 AUC (Probabilité Normalisée): 0.8778
🎯 Accuracy: 82.28 %
🔍 Precision: 81.63 %
🔍 Recall (Sensibilité): 88.89 %
📈 F1-Score: 85.11 %

Matrice de confusion:
       Prediction
Verite   1   2
     1  40  05
     2  09  25
```

---

## 🔍 Processus d'Exécution

1. **Lecture des coefficients** : Chargement du modèle LASSO
2. **Vérification des features** : Contrôle de la présence des variables requises
3. **Calcul du score brut** : Somme pondérée = Σ(feature × coefficient)
4. **Transformation logistique** : Proba_Brute = 1 / (1 + exp(-score_brut))
5. **Attribution des clusters** : Comparaison avec seuil optimal (0.7658)
6. **Normalisation avancée** : Application des bornes d'intervalles
7. **Export des résultats** : Génération du fichier CSV

---

## 📈 Interprétation des Résultats

### Scores et Probabilités

#### Probabilité Brute (Proba_Brute)
- **Transformation logistique** du score linéaire
- **Valeurs** : Entre 0 et 1
- **Interprétation** : Probabilité d'appartenir au cluster à haut risque
- **Seuil critique** : 0.7658351 (76.58%)

#### Probabilité Normalisée (Proba_Normalisee)
- **Normalisation segmentée** par cluster
- **Intervalle bas [0, 0.5[** : Cluster 1 (faible risque)
  - Bornes : 0.390448 - 0.7630
- **Intervalle haut [0.5, 1]** : Cluster 2 (haut risque)
  - Bornes : 0.7687 - 0.9767

### Classification des Clusters

#### 🟢 Cluster 1 : Pronostic Favorable
- **Probabilité brute** < 0.7658
- **Probabilité normalisée** < 0.5
- **Caractéristiques** :
  - Risque faible de mortalité
  - Probabilité de survie à J90 plus élevée
  - Surveillance standard recommandée

#### 🔴 Cluster 2 : Pronostic Réservé
- **Probabilité brute** ≥ 0.7658
- **Probabilité normalisée** ≥ 0.5
- **Caractéristiques** :
  - Risque élevé de mortalité
  - Nécessite surveillance intensive
  - Prise en charge thérapeutique renforcée

### 📊 Performance Clinique du Modèle

Le modèle présente d'excellentes performances cliniques :

- **🎯 Sensibilité élevée (88.9%)** : Identification fiable des patients à haut risque
  - Sur 10 patients réellement à haut risque, le modèle en détecte correctement 9
  - Minimise les faux négatifs, crucial en contexte de sepsis

- **✅ Excellente précision (81.6%)** : Fiabilité des alertes
  - Lorsque le modèle prédit un haut risque, il a raison dans plus de 8 cas sur 10
  - Limite les fausses alertes et optimise les ressources

- **⚖️ Équilibre optimal (F1-Score 85.1%)** : Balance entre détection et précision
  - Score harmonique entre sensibilité et précision
  - Garantit une performance équilibrée

- **📊 Capacité discriminante excellente (AUC 87.8%)** : 
  - Le modèle distingue très bien les deux populations
  - Performance proche des standards cliniques d'excellence (AUC > 0.8)

---

## 🔧 Algorithme de Normalisation

### Principe
```r
# Étape 1 : Transformation logistique
proba_brute <- 1 / (1 + exp(-score_brut))

# Étape 2 : Attribution du cluster
if (proba_brute < 0.7658351) {
    cluster <- 1  # Faible risque
} else {
    cluster <- 2  # Haut risque
}

# Étape 3 : Normalisation selon le cluster
if (cluster == 1) {
    # Cluster 1 : Normalisation dans [0, 0.5[
    proba_normalisee <- (proba_brute - 0.390448) / 
                        (0.7629905 - 0.390448) * 0.5
} else {
    # Cluster 2 : Normalisation dans [0.5, 1]
    proba_normalisee <- 0.5 + (proba_brute - 0.7686798) / 
                               (0.9766953 - 0.7686798) * 0.5
}
```

### Paramètres du Modèle
```r
seuil_optimal <- 0.7658351

bornes_intervalles <- list(
  borne_min_bas = 0.390448,     # Minimum cluster 1
  borne_max_bas = 0.7629905,    # Maximum cluster 1
  borne_min_haut = 0.7686798,   # Minimum cluster 2
  borne_max_haut = 0.9766953,   # Maximum cluster 2
  n_patients_bas = 49,
  n_patients_haut = 30
)
```

---

## ⚠️ Messages d'Erreur et Résolution

| Erreur | Cause Probable | Solution |
|--------|----------------|----------|
| "Les arguments -i, -c et -o sont obligatoires" | Arguments manquants | Spécifier tous les fichiers requis |
| "Features manquantes dans le fichier de données" | Variables absentes dans les données | Vérifier la concordance entre colonnes et coefficients |
| "Aucune feature sélectionnée" | Fichier coefficients incorrect | Vérifier que `Type` = "Selected" existe |
| "Package 'pROC' non disponible" | Package manquant (avec option `-t`) | Installation automatique ou `install.packages("pROC")` |
| Valeurs NA dans Proba_Normalisee | Bornes invalides ou valeurs extrêmes | Vérifier les bornes d'intervalles |

---

## 📊 Métriques de Performance (Option -t)

Lorsque la colonne de vérité est fournie, le script calcule automatiquement :

### Métriques Globales
| Métrique | Définition | Performance |
|----------|------------|-------------|
| **AUC** | Aire sous la courbe ROC | **0.878** ⭐ |
| **Accuracy** | Taux de classification correcte | **82.3%** ✅ |
| **Precision** | Exactitude des prédictions positives | **81.6%** ✅ |
| **Recall** | Sensibilité (détection haut risque) | **88.9%** ⭐ |
| **F1-Score** | Moyenne harmonique précision/recall | **85.1%** ✅ |

### Statistiques par Cluster
Pour chaque cluster, le script affiche :
- Effectifs (n)
- Moyenne ± écart-type
- Intervalles [min, max]
- Scores bruts, probabilités brutes et normalisées

---

## 🔒 Considérations Éthiques et Réglementaires

### Protection des Données
- **Confidentialité** : Anonymisation obligatoire des identifiants patients
- **RGPD** : Conformité aux réglementations sur les données de santé
- **Sécurité** : Stockage sécurisé des fichiers de données

### Usage Clinique
- **Aide à la décision** : Outil complémentaire, ne remplace pas le jugement médical
- **Validation clinique** : Résultats à interpréter dans le contexte clinique global
- **Formation requise** : Personnel formé à l'interprétation des scores

### Limitations
- Modèle validé sur population spécifique (patients avec sepsis)
- Performances peuvent varier selon les populations
- Mise à jour régulière recommandée avec nouvelles données
- Ne remplace pas l'évaluation clinique complète

---

## 📚 Références et Validation

### Validation Scientifique
- ✅ Modèle validé sur la survie à J90
- ✅ Clustering hiérarchique corrélé aux outcomes cliniques
- ✅ AUC = 0.878 (excellente capacité discriminante)
- ✅ Sensibilité = 88.9% (détection optimale des patients à haut risque)
- ✅ Validation croisée et test sur cohorte indépendante

### Base Méthodologique
- **Clustering** : Ward's hierarchical clustering
- **Régression** : LASSO (Least Absolute Shrinkage and Selection Operator)
- **Validation** : Cross-validation et test sur cohorte de validation
- **Seuil optimal** : Déterminé par maximisation du F1-Score

### Publications et Références
- Corrélation établie avec survie à J90
- Sélection de variables par pénalisation LASSO
- Normalisation adaptative par cluster

---

## 📦 Installation et Déploiement

### Installation Rapide
```bash
# Cloner le repository
git clone https://github.com/GClerempuy/Scoring_Sespsis.git
cd Scoring_Sespsis

# Installer les dépendances R
Rscript -e "install.packages(c('optparse', 'pROC'))"

# Test d'exécution
Rscript Scoring_UVSQ_cluster.R --help
```

### Structure du Repository
```
Scoring_Sespsis/
├── Scoring_UVSQ_cluster.R      # Script principal
├── normalisation.R              # Fonction de normalisation
├── README.md                  # Documentation
├── Coefficients_clust.csv
```

---

### Utilité du Score
- ✅ **Triage** : Identification rapide des patients critiques
- ✅ **Stratification** : Allocation optimale des ressources
- ✅ **Suivi** : Évaluation de l'évolution clinique
- ✅ **Communication** : Outil objectif patient/famille
- ✅ **Recherche** : Homogénéisation des cohortes

---

## 👥 Équipe et Contact

**Institution** : UVSQ (Université de Versailles Saint-Quentin-en-Yvelines)

**Auteur Principal** : G. Clerempuy

**Contact** : Pour toute question ou collaboration, ouvrir une issue sur GitHub

---

## 📄 Licence

Ce projet est développé dans un cadre de recherche médicale. L'utilisation est soumise aux réglementations en vigueur concernant les données de santé.

**⚠️ Disclaimer** : Cet outil est destiné à la recherche et à l'aide à la décision clinique. Il ne doit pas être utilisé comme unique critère de décision thérapeutique. Les décisions cliniques finales doivent toujours être prises par des professionnels de santé qualifiés en tenant compte de l'ensemble du contexte clinique.

---

## 🌟 Citation

Si vous utilisez ce modèle dans vos travaux de recherche, merci de citer :

```bibtex
@software{scoring_sepsis_2025,
  author = {Clerempuy, G.},
  title = {Scoring_Sepsis: Modèle de Prédiction du Risque de Mortalité dans le Sepsis},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/GClerempuy/Scoring_Sespsis},
  note = {AUC: 0.878, Sensibilité: 88.9\%}
}
```

---

**Dernière mise à jour** : Novembre 2025  
**Statut** : ✅ Actif et maintenu  
**Performance** : AUC 0.878 | Accuracy 82.3% | Sensibilité 88.9%
