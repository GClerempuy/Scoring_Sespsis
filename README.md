# Scoring_Sespsis

# Projet de Scoring et Classification des Patients Septiques

## 📋 Description du Projet

Ce projet vise à développer un modèle de prédiction pour classifier les patients atteints de sepsis selon leur probabilité de survie. Le système utilise une approche combinant apprentissage non-supervisé et régression logistique pour identifier des profils de patients à risque.

### Contexte Médical
Le sepsis est une réponse inflammatoire systémique grave à une infection, représentant une urgence médicale majeure avec un taux de mortalité élevé. L'identification précoce des patients à haut risque est cruciale pour optimiser la prise en charge thérapeutique et améliorer les résultats cliniques.

### Objectifs
- **Principal** : Stratifier les patients septiques en clusters selon leur risque de mortalité
- **Secondaire** : Fournir un score de risque normalisé pour aide à la décision clinique
- **Validation** : Corrélation établie avec la survie à J90

## 🔬 Méthodologie

### 1. Clustering Hiérarchique Non-Supervisé
- Identification de groupes naturels de patients basée sur leurs caractéristiques cliniques et biologiques
- Clustering validé par corrélation avec la survie à 90 jours

### 2. Modèle de Régression Logistique LASSO
- Sélection automatique des features les plus prédictives
- Génération de coefficients pour le calcul du score de risque
- Seuil optimal déterminé : 31.84% de la distribution des scores

### 3. Attribution des Clusters
- **Cluster 1** : Patients à faible risque (score < seuil)
- **Cluster 2** : Patients à haut risque (score ≥ seuil)

## 🛠️ Prérequis Techniques

### Environnement R
```bash
R version >= 3.6.0
```

### Packages R Requis
```R
install.packages("optparse")
```

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
CRP,0.0234,Selected
Lactate,0.0456,Selected
Age,0.0123,Selected
```

### Fichier de Sortie

#### `TEST_clust_scoring.csv`
Contient :
- Toutes les données originales
- `Score_Raw` : Score brut (somme pondérée)
- `Score` : Score normalisé [0-1]
- `Cluster` : Attribution du cluster (1 ou 2)

## 📊 Utilisation du Script

### Syntaxe de Base
```bash
Rscript Scoring_UVSQ_cluster.R -i Data_metadata.csv -c Coefficients_clust.csv -o TEST_clust_scoring.csv
```

### Options Disponibles

| Option | Argument Long | Description | Obligatoire |
|--------|--------------|-------------|-------------|
| `-i` | `--input` | Fichier de données patients | ✅ Oui |
| `-c` | `--coefficients` | Fichier des coefficients LASSO | ✅ Oui |
| `-o` | `--output` | Fichier de sortie avec scores | ✅ Oui |
| `-v` | `--verbose` | Mode détaillé (affiche les étapes) | ❌ Non |

### Exemples d'Utilisation

#### Mode Standard
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv
```

#### Mode Verbose (Recommandé pour Debug)
```bash
Rscript Scoring_UVSQ_cluster.R \
    -i Data_metadata.csv \
    -c Coefficients_clust.csv \
    -o resultats_scoring.csv \
    -v
```

## 🔍 Processus d'Exécution

1. **Lecture des coefficients** : Chargement du modèle LASSO
2. **Vérification des features** : Contrôle de la présence des variables requises
3. **Calcul du score brut** : Somme pondérée des features sélectionnées
4. **Attribution des clusters** : Application du seuil optimal (31.84%)
5. **Normalisation** : Transformation des scores sur l'échelle [0-1]
6. **Export** : Génération du fichier de résultats

## 📈 Interprétation des Résultats

### Score de Risque
- **Score proche de 0** : Risque faible de mortalité
- **Score proche de 1** : Risque élevé de mortalité
- **Seuil critique** : 0.3184 (31.84%)

### Clusters
- **Cluster 1** : Groupe à pronostic favorable
  - Score normalisé < 0.3184
  - Probabilité de survie à J90 plus élevée
  
- **Cluster 2** : Groupe à pronostic réservé
  - Score normalisé ≥ 0.3184
  - Nécessite une surveillance et prise en charge intensifiées

## ⚠️ Messages d'Erreur et Résolution

| Erreur | Cause | Solution |
|--------|-------|----------|
| "Les arguments -i, -c et -o sont obligatoires" | Arguments manquants | Spécifier tous les fichiers requis |
| "Features manquantes dans le fichier de données" | Variables absentes | Vérifier la concordance entre données et coefficients |
| "Aucune feature sélectionnée" | Fichier coefficients incorrect | Vérifier la colonne "Type" = "Selected" |

## 🔒 Considérations Éthiques et Réglementaires

- **Confidentialité** : Anonymisation obligatoire des identifiants patients
- **RGPD** : Conformité aux réglementations sur les données de santé
- **Usage clinique** : Outil d'aide à la décision, ne remplace pas le jugement médical
- **Validation** : Résultats à interpréter dans le contexte clinique global

## 📚 Références et Validation

- Modèle validé sur la survie à J90
- Clustering hiérarchique non-supervisé corrélé aux outcomes cliniques
- Régression logistique LASSO pour sélection optimale des variables

## 👥 Équipe et Contact

**Institution** : UVSQ (Université de Versailles Saint-Quentin-en-Yvelines)

## 📄 Licence

Ce projet est développé dans un cadre de recherche médicale. L'utilisation est soumise aux réglementations en vigueur concernant les données de santé.

---

*Dernière mise à jour : Documentation générée pour le script Scoring_UVSQ_cluster.R*
