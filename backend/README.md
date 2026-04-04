# Firebase Firestore Backend

En esta carpeta están los archivos de configuración del backend de Firebase usados por la app:

- Reglas de **Firestore**: `firestore.rules`
- Reglas de **Storage**: `storage.rules`
- Configuración de **Emuladores**: `firebase.json`
- Índices de **Firestore**: `firestore.indexes.json`
- Documentación del **schema**: `docs/DB_SCHEMA.md`

---

## DB Schema (Firestore)

La estructura de la base de datos para la funcionalidad de “Journalist Articles” está documentada aquí:

- `backend/docs/DB_SCHEMA.md`

Incluye:
- `/articles/{articleId}`
- Subcolecciones: `/reactions/{uid}` y `/comments/{commentId}`
- `/users/{uid}`
- Storage: `media/articles/{articleId}/thumbnail.jpg`

---

## Getting Started

Antes de trabajar el backend, asegúrate de tener un proyecto Firebase con:
- Firestore
- Storage
- Emulator Suite

---

## Deploying (Firestore + Storage rules)

### 1) Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2) Login
```bash
firebase login
```

### 3) Set project id
Edita `.firebaserc` con el Project ID de tu proyecto Firebase.

### 4) Deploy
```bash
firebase deploy
```

> Nota: este comando despliega reglas de Firestore/Storage y cualquier configuración declarada en `firebase.json`.

---

## Running locally (Emulator Suite)

```bash
firebase emulators:start
```

Puertos (según `firebase.json`):
- Firestore: `8080`
- Auth: `9099`
- Storage: `9199`
- Emulator UI: habilitado