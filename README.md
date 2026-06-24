# PayRappel

**Application mobile de gestion des paiements et de rappels automatiques pour les petites entreprises et travailleurs indépendants.**

Disponible sur **Android** et **iOS**.

---

## Présentation

PayRappel est une solution simple et efficace pour gérer vos clients, créer des factures professionnelles, suivre les paiements partiels et envoyer des rappels automatiques aux clients en retard de paiement.

Conçue pour les entrepreneurs, freelances et petites entreprises d'Afrique francophone, l'application fonctionne en **FCFA** et supporte le mode **hors ligne**.

---

## Fonctionnalités

### Gestion des clients
- Créer, modifier et supprimer des fiches clients
- Importer les contacts directement depuis le téléphone
- Consulter l'historique complet de chaque client (factures, paiements)

### Facturation
- Créer des factures avec articles, quantités et montants
- Suivre le statut de chaque facture : `Brouillon`, `Partiel`, `Payé`, `En retard`
- Enregistrer des paiements partiels et calculer automatiquement le solde restant

### Templates de factures
- 4 modèles de design : Classique, Moderne, Minimaliste, Audacieux
- Éditeur de sections personnalisable (ajouter, supprimer, réorganiser)
- Prévisualisation en temps réel

### Export
- Génération de **PDF** et **Excel** (plan Pro)
- Partage direct depuis l'application

### Rappels automatiques
- Planifier des rappels avant, à la date ou après l'échéance
- Notifications push (plan Gratuit)
- Rappels WhatsApp (plan Pro)

### Profil entreprise
- Nom, logo, coordonnées, mentions légales
- Logo affiché sur les factures exportées

### Modes de paiement
- Configurer les moyens de paiement acceptés : Orange Money, Wave, MTN MoMo, Moov Money, Djamo, Stripe, PayPal, VISA, Mastercard

---

## Plans tarifaires

| Fonctionnalité | Gratuit | Pro |
|---|:---:|:---:|
| Clients | 20 max | Illimité |
| Opérations/mois | 30 max | Illimité |
| Notifications push | ✅ | ✅ |
| Export PDF / Excel | ❌ | ✅ |
| Rappels WhatsApp | ❌ | ✅ |
| Templates personnalisés | ❌ | ✅ |

---

## Stack technique

| Couche | Technologie |
|---|---|
| Framework | Flutter 3.x (Dart) |
| Authentification | Firebase Auth (email + mode invité anonyme) |
| Base de données | Cloud Firestore (offline-first) |
| Notifications | Firebase Cloud Messaging + flutter_local_notifications |
| Navigation | go_router |
| État | Provider / ChangeNotifier |
| Export PDF | package `pdf` + `printing` |
| Export Excel | package `excel` |
| Graphiques | fl_chart |
| Locale | Français (fr_FR), FCFA |

---

## Architecture

```
lib/
├── core/           → Constantes, utilitaires, formatters
├── data/           → Firebase : modèles, repositories, services
├── domain/         → Règles métier (calcul solde, statut facture)
├── presentation/   → Écrans et widgets (un dossier par feature)
└── providers/      → State management (Provider)
```

**Flux de données :** les écrans appellent les repositories (couche `data/`) qui communiquent avec Firebase. Les règles métier (ex. calcul du solde restant) vivent dans `domain/`, appelées par les repositories ou les écrans.

---

## Sécurité

- Règles Firestore déployées : chaque utilisateur accède uniquement à ses propres données
- Les champs d'abonnement (`isPro`, `proExpiry`, `planType`) sont immuables côté client — modification possible uniquement via l'Admin SDK (Cloud Functions)
- Mode invité : les utilisateurs anonymes ont un UID Firebase et peuvent convertir leur compte en compte email sans perte de données
- Persistance hors ligne : Firestore cache toutes les données localement (`cacheSizeBytes: CACHE_SIZE_UNLIMITED`)

---

## Prérequis

- Flutter SDK >= 3.5.4
- Compte Firebase (projet configuré avec FlutterFire CLI)
- Android SDK (minSdk 23 / Android 6.0+)
- Xcode (pour build iOS, macOS requis)

---

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/ton-utilisateur/payrappel.git
cd payrappel

# Installer les dépendances
flutter pub get

# Lancer en développement
flutter run
```

> Les fichiers `lib/firebase_options.dart`, `android/app/google-services.json` et `ios/Runner/GoogleService-Info.plist` sont exclus du dépôt. Configure ton propre projet Firebase via la [FlutterFire CLI](https://firebase.flutter.dev/docs/cli).

---

## Commandes utiles

```bash
# Analyser le code
flutter analyze

# Lancer les tests
flutter test

# Build Android (AAB pour Play Store)
flutter build appbundle --release

# Build iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## Licence

Projet propriétaire — tous droits réservés.
