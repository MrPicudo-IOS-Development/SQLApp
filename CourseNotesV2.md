# Curso: Desarrollo y Mantenimiento de SQLApp — Versión 2
### Material de estudio — 20 sesiones

> **Objetivo**: Que un estudiante universitario pueda entender, mantener, extender y escalar la versión 2 completa de SQLApp, incluyendo las cuatro pestañas, el sistema de dos bases de datos separadas, el módulo de ejercicios interactivos, y todas las buenas prácticas de programación empleadas.

---

## Índice de Sesiones

| # | Tema | Archivos clave |
|---|------|----------------|
| 1 | Visión General y Diferencias con v1 | `SQLAppApp.swift`, `ContentView.swift` |
| 2 | Las Dos Bases de Datos | `SQLAppApp.swift`, `SQLiteDatabaseService.swift` |
| 3 | El Protocolo de Servicio Ampliado | `DatabaseServiceProtocol.swift` |
| 4 | Implementación SQLite: Historia y Múltiples Instancias | `SQLiteDatabaseService.swift` |
| 5 | Modelos de Datos Nuevos | `TableSummary.swift`, `ExerciseBlock.swift`, `Exercise.swift`, `ExerciseAttemptRecord.swift` |
| 6 | ViewModels — La Familia Completa | `QueryEditorViewModel.swift`, `DatabaseViewModel.swift`, `TableBrowserViewModel.swift`, `SettingsViewModel.swift` |
| 7 | ExercisesViewModel — Pieza Central del Módulo | `ExercisesViewModel.swift` |
| 8 | Pestaña SQL Editor | `QueryEditorView.swift`, `SQLTextEditorView.swift`, `SQLTextEditorCoordinator.swift` |
| 9 | Pestaña Database | `DatabaseView.swift`, `TableCardView.swift`, `TableDetailView.swift`, `TableListView.swift` |
| 10 | Historial Persistente | `QueryHistoryListView.swift`, `HistoryQueryCardView.swift`, `HistoryQueryDetailView.swift` |
| 11 | Pestaña Exercises — Diseño General | `ExercisesView.swift`, `ExerciseBlockCardView.swift` |
| 12 | ExerciseDetailView — Máquina de Estados | `ExerciseDetailView.swift` |
| 13 | BlockResultsView — Pantalla de Resultados | `BlockResultsView.swift` |
| 14 | Carga de Datos con JSON | `dinosaursInfo.json`, `ExercisesViewModel.swift` |
| 15 | Navegación por Valores en SwiftUI | `DatabaseView.swift`, `ExercisesView.swift` |
| 16 | UIViewRepresentable y Syntax Highlighting (actualizado) | `SQLTextEditorView.swift`, `SQLTextEditorCoordinator.swift`, `SQLSyntaxHighlighter.swift` |
| 17 | Persistencia: UserDefaults, SQLite y Migración | `SettingsViewModel.swift`, `SQLAppApp.swift` |
| 18 | Concurrencia: async/await, MainActor y DispatchQueue | Transversal |
| 19 | Testing y Arquitectura Testeable | Transversal |
| 20 | Resumen de Buenas Prácticas y Extensibilidad | Transversal |

---

## Sesión 1: Visión General y Diferencias con v1

### Objetivos
- Entender qué cambió de la versión 1 a la versión 2.
- Reconocer el nuevo árbol de composición.
- Identificar las cuatro pestañas y sus responsabilidades.

### Archivos a revisar
1. `SQLAppApp.swift`
2. `ContentView.swift`

---

### 1.1 — Las Cuatro Pestañas

La versión 2 expande la app de dos a **cuatro pestañas**:

| Pestaña | Icono SF | ViewModel(s) | Base de datos |
|---------|----------|--------------|---------------|
| SQL Editor | `terminal` | `QueryEditorViewModel` | User |
| Database | `cylinder` | `DatabaseViewModel` + `TableBrowserViewModel` | User |
| Exercises | `book` | `ExercisesViewModel` + `QueryEditorViewModel` | App |
| Settings | `gearshape` | `SettingsViewModel` | — |

La pestaña **Database** es completamente nueva: reemplaza y expande lo que antes era simplemente una lista de tablas, añadiendo `TableCardView`, historial persistente, y navegación multi-nivel.

La pestaña **Exercises** es la mayor adición: un sistema interactivo de aprendizaje SQL con bloques de ejercicios, validación de respuestas, y seguimiento de puntuación.

---

### 1.2 — La Composición Raíz en ContentView

`ContentView` sigue siendo la raíz de composición, pero ahora recibe **dos** servicios de base de datos:

```swift
init(
    userDatabaseService: any DatabaseServiceProtocol,
    appDatabaseService: any DatabaseServiceProtocol
) {
    // User database ViewModels
    self._queryEditorVM = State(initialValue: QueryEditorViewModel(databaseService: userDatabaseService))
    self._tableBrowserVM = State(initialValue: TableBrowserViewModel(databaseService: userDatabaseService))
    self._databaseVM = State(initialValue: DatabaseViewModel(databaseService: userDatabaseService))

    // App database ViewModels
    self._exercisesEditorVM = State(initialValue: QueryEditorViewModel(databaseService: appDatabaseService))
    self._exercisesVM = State(initialValue: ExercisesViewModel(databaseService: appDatabaseService))
}
```

**¿Por qué dos QueryEditorViewModel?**
Porque el editor de SQL del tab principal y el editor dentro de los ejercicios deben ser **completamente independientes**. Si compartieran el mismo ViewModel, escribir en un editor borraría el estado del otro.

`SettingsViewModel` sigue siendo el único ViewModel **compartido** entre tabs, para que el cambio de color de keywords se refleje simultáneamente en todos los editores.

---

### 1.3 — Sintaxis Moderna de Tabs (iOS 18)

La versión 2 usa la nueva API de `Tab` de iOS 18:

```swift
TabView {
    Tab("SQL Editor", systemImage: "terminal") {
        QueryEditorView(...)
    }
    Tab("Database", systemImage: "cylinder") {
        DatabaseView(...)
    }
    // ...
}
```

Esta sintaxis es preferida sobre el `.tabItem` anterior porque es más declarativa y permite futuras extensiones como tabs personalizados o barra de tabs adaptativa.

---

### Ejercicio Sesión 1
Dibuja el árbol completo de dependencias de la v2:
`SQLAppApp → ContentView → [QueryEditorView, DatabaseView, ExercisesView, SettingsView]`
Para cada vista, indica qué ViewModels recibe y a qué base de datos apuntan.

---

## Sesión 2: Las Dos Bases de Datos

### Objetivos
- Entender la arquitectura de separación de bases de datos.
- Saber por qué se separaron y cuándo usar cada una.
- Comprender la migración de datos legados.

### Archivos a revisar
1. `SQLAppApp.swift`
2. `SQLiteDatabaseService.swift` (init)

---

### 2.1 — Por Qué Dos Bases de Datos

| | `user_database.sqlite` | `app_database.sqlite` |
|--|------------------------|----------------------|
| **Propósito** | Sandbox del usuario | Datos controlados por la app |
| **Historial** | Sí (`_query_history`) | No |
| **Contenido** | Tablas del usuario | Tablas de ejercicios (Dinosaurs, etc.) |
| **Mutabilidad** | El usuario puede crear/borrar tablas | Solo la app escribe (al cargar JSON) |
| **Persistencia** | Entre sesiones | Entre sesiones |

La **separación es crítica**: si los ejercicios usaran la misma base de datos que el usuario, las tablas de dinosaurios aparecerían en la pestaña Database y el usuario podría borrarlas accidentalmente.

---

### 2.2 — Creación de los Servicios en SQLAppApp

```swift
init() {
    Self.migrateLegacyDatabaseIfNeeded()

    self.userDatabaseService = SQLiteDatabaseService(
        databaseName: "user_database.sqlite",
        enableHistory: true
    )
    self.appDatabaseService = SQLiteDatabaseService(
        databaseName: "app_database.sqlite",
        enableHistory: false
    )
}
```

El parámetro `enableHistory: false` en la `appDatabaseService` significa que la tabla interna `_query_history` **no se crea** en esa base de datos. Los ejercicios no necesitan historial.

---

### 2.3 — Migración de Datos Legados

La versión 1 guardaba la base de datos como `SQLApp.sqlite`. La versión 2 la renombra a `user_database.sqlite`. Para no perder los datos de usuarios que actualizan la app:

```swift
private static func migrateLegacyDatabaseIfNeeded() {
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory, in: .userDomainMask
    ).first!
    let legacyURL = documentsURL.appendingPathComponent("SQLApp.sqlite")
    let newURL = documentsURL.appendingPathComponent("user_database.sqlite")

    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: legacyURL.path),
       !fileManager.fileExists(atPath: newURL.path) {
        try? fileManager.moveItem(at: legacyURL, to: newURL)
    }
}
```

**Buena práctica**: La migración es **idempotente** (segura de llamar varias veces): solo actúa si el archivo legado existe Y el nuevo aún no existe. Si falla silenciosamente (con `try?`), SQLite crea automáticamente un archivo nuevo, por lo que la app no se rompe.

**Cuándo llamarla**: En `init()` de `SQLAppApp`, **antes** de crear los servicios, para que cuando `SQLiteDatabaseService` intente abrir `user_database.sqlite`, ya exista el archivo renombrado.

---

### Ejercicio Sesión 2
Escribe el código para agregar una tercera base de datos `temp_database.sqlite` que se borre automáticamente al arrancar la app (para un scratchpad efímero). ¿Dónde crearías la instancia del servicio? ¿Con `enableHistory: true` o `false`?

---

## Sesión 3: El Protocolo de Servicio Ampliado

### Objetivos
- Entender los tres métodos nuevos de historial.
- Saber por qué el protocolo es único aunque hay dos bases de datos.

### Archivos a revisar
1. `DatabaseServiceProtocol.swift`

---

### 3.1 — Los Métodos de la Versión 2

La versión 1 tenía 5 métodos. La versión 2 añade **3 más para historial persistente**:

```swift
protocol DatabaseServiceProtocol: Sendable {
    // --- v1 (sin cambios) ---
    func executeNonQuery(_ sql: String) async throws -> Int
    func executeQuery(_ sql: String) async throws -> QueryResult
    func listTables() async throws -> [String]
    func getTableInfo(_ tableName: String) async throws -> TableInfo
    func getTableData(_ tableName: String, limit: Int) async throws -> QueryResult

    // --- NUEVOS en v2 ---
    func saveHistoryItem(_ item: QueryHistoryItem) async throws
    func loadHistory() async throws -> [QueryHistoryItem]
    func clearHistory() async throws
}
```

**Nota**: `getTableData` ahora recibe un parámetro `limit: Int` explícito (en v1 era hardcoded en la implementación).

---

### 3.2 — Un Solo Protocolo para Dos Bases de Datos

Ambas instancias (`userDatabaseService` y `appDatabaseService`) implementan **el mismo protocolo completo**, incluyendo los métodos de historial. Sin embargo, `appDatabaseService` fue creada con `enableHistory: false`, por lo que no tiene la tabla `_query_history`.

¿Qué pasa si alguien llama `appDatabaseService.saveHistoryItem(...)` por error?
SQLite retorna un error (la tabla no existe), que se propaga como `DatabaseError`. La app no se rompe.

**Alternativa de diseño que NO se tomó**: Dividir el protocolo en `ReadWriteProtocol` y `FullProtocol`. Esto hubiera sido más seguro a nivel de tipos pero añadiría complejidad sin beneficio funcional actual (ningún ViewModel de ejercicios llama a métodos de historial).

---

### Ejercicio Sesión 3
¿Qué cambios habría que hacer si se añadiera un método `func backup(to url: URL) async throws` al protocolo? Lista todos los archivos que necesitarían modificarse.

---

## Sesión 4: Implementación SQLite — Historia y Múltiples Instancias

### Objetivos
- Entender cómo se implementan los métodos de historial.
- Comprender el parámetro `enableHistory` y el `DispatchQueue` dinámico.

### Archivos a revisar
1. `SQLiteDatabaseService.swift` (completo)

---

### 4.1 — El DispatchQueue Dinámico

En la versión 1, el queue tenía un label fijo:
```swift
// v1 — problemático con múltiples instancias
private let queue = DispatchQueue(label: "com.sqlapp.database", qos: .userInitiated)
```

En la versión 2, el label incluye el nombre del archivo:
```swift
// v2 — identificable en Instruments/debugging
self.queue = DispatchQueue(label: "com.sqlapp.database.\(databaseName)", qos: .userInitiated)
```

Con dos instancias, los queues serán:
- `com.sqlapp.database.user_database.sqlite`
- `com.sqlapp.database.app_database.sqlite`

Esto es crucial para **depuración**: en Xcode Instruments o en un crash log, puedes identificar exactamente qué base de datos estaba activa.

---

### 4.2 — Persistencia del Historial en SQLite

La tabla interna `_query_history` (con prefijo `_` para distinguirla de tablas de usuario) se crea con:

```sql
CREATE TABLE IF NOT EXISTS _query_history (
    id TEXT PRIMARY KEY,          -- UUID del QueryHistoryItem
    sql TEXT NOT NULL,            -- Consulta ejecutada
    executed_at REAL NOT NULL,    -- Date como Unix timestamp (Real = Double)
    was_successful INTEGER NOT NULL,  -- Bool en SQLite (0/1)
    rows_affected INTEGER,        -- Nulo para SELECT
    error_message TEXT            -- Nulo para ejecuciones exitosas
)
```

**¿Por qué TEXT para el UUID?** SQLite no tiene tipo UUID. Se almacena como string. La implementación usa `item.id.uuidString` al guardar y `UUID(uuidString:)` al leer.

**¿Por qué REAL para la fecha?** SQLite no tiene tipo Date. Se usa `Date().timeIntervalSince1970` (un `Double`) al guardar y `Date(timeIntervalSince1970:)` al leer.

**¿Por qué INTEGER para Bool?** SQLite no tiene tipo Bool. `0 = false`, `1 = true`.

---

### 4.3 — saveHistoryItem

```swift
func saveHistoryItem(_ item: QueryHistoryItem) async throws {
    try await performOnQueue { db in
        let sql = """
            INSERT OR REPLACE INTO _query_history
            (id, sql, executed_at, was_successful, rows_affected, error_message)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed(...)
        }
        // Bind parameters con sqlite3_bind_text, sqlite3_bind_double, etc.
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.queryFailed(...)
        }
        return ()
    }
}
```

**`INSERT OR REPLACE`**: Si ya existe un registro con el mismo `id`, lo reemplaza. Esto hace la operación idempotente.

**Parámetros con `?`**: Siempre usar parámetros enlazados (`sqlite3_bind_*`) en lugar de interpolación de strings. La interpolación directa es vulnerable a **SQL Injection**.

---

### Ejercicio Sesión 4
Lee la implementación de `loadHistory()` completa. ¿En qué orden devuelve los registros? ¿Cómo mapea cada columna SQLite de vuelta a un `QueryHistoryItem`?

---

## Sesión 5: Modelos de Datos Nuevos

### Objetivos
- Conocer los cuatro modelos nuevos de v2.
- Entender cuándo un modelo necesita `Hashable` vs `Identifiable` vs `Sendable`.

### Archivos a revisar
1. `Models/TableSummary.swift`
2. `Models/ExerciseBlock.swift`
3. `Models/Exercise.swift`
4. `Models/ExerciseAttemptRecord.swift`

---

### 5.1 — TableSummary

```swift
struct TableSummary: Identifiable, Sendable {
    let id: String       // El nombre de la tabla es su ID único
    let name: String
    let columnCount: Int
    let rowCount: Int
}
```

**¿Por qué no usa TableInfo?** `TableInfo` contiene el schema completo (todas las columnas con tipos, constraints, etc.) — es costoso de cargar para 10 tablas simultáneamente. `TableSummary` es un resumen ligero para la vista de lista. Este es el **patrón Projection**: cargar solo los datos que la vista necesita, no el objeto completo.

---

### 5.2 — ExerciseBlock

```swift
struct ExerciseBlock: Identifiable, Hashable {
    let id = UUID()
    let imageName: String        // SF Symbol para la tarjeta
    let sqlKeywords: [String]    // Keywords que introduce el bloque
    let summary: String          // Descripción breve
    let tableNames: [String]     // Tablas requeridas en app_database
    let jsonFileName: String     // Archivo JSON bundled (sin extensión)
    let exercises: [Exercise]    // Los 5 ejercicios del bloque

    var title: String { tableNames.joined(separator: ", ") }
}
```

`ExerciseBlock` conforma `Hashable` porque se usa como **valor de navegación** en el `NavigationStack`:

```swift
NavigationLink(value: Destination.exerciseDetail(block)) { ... }
```

Para que un enum con valores asociados sea `Hashable`, todos sus valores asociados deben serlo. Por eso `ExerciseBlock` implementa `Hashable` manualmente usando solo su `id`.

---

### 5.3 — Exercise

```swift
struct Exercise: Identifiable {
    let id = UUID()
    let title: String        // "Dinosaurs 1"
    let instructions: String // Qué debe escribir el usuario
    let solutionSQL: String  // Query canónica cuyo OUTPUT es la respuesta correcta
}
```

**`solutionSQL` no es la respuesta única**: La validación compara el **output** de la query del usuario contra el output de `solutionSQL`. Cualquier query que produzca el mismo resultado (mismas columnas, mismas filas, mismo orden) es aceptada.

---

### 5.4 — ExerciseAttemptRecord

```swift
struct ExerciseAttemptRecord: Identifiable, Hashable {
    let id = UUID()
    let exerciseTitle: String   // "Dinosaurs 3"
    let queryUsed: String       // La última query que escribió el usuario
    let wasCorrect: Bool        // true si la respondió sin ayuda
}
```

`wasCorrect` es `false` si el usuario usó "See Answer" o si avanzó sin resolver el ejercicio. Esto garantiza que el score refleje el conocimiento real del usuario.

Conforma `Hashable` porque aparece en el enum de destino de navegación:

```swift
case blockResults(ExerciseBlock, [ExerciseAttemptRecord])
```

---

### Ejercicio Sesión 5
¿Qué pasaría si `ExerciseBlock` no conformara `Hashable`? ¿Qué error del compilador obtendrías? Explica qué hace `Equatable` vs `Hashable` y por qué `NavigationLink(value:)` requiere el segundo.

---

## Sesión 6: ViewModels — La Familia Completa

### Objetivos
- Entender los cuatro ViewModels "clásicos" y sus responsabilidades.
- Ver cómo `DatabaseViewModel` separa concerns de `TableBrowserViewModel`.

### Archivos a revisar
1. `ViewModels/QueryEditorViewModel.swift`
2. `ViewModels/DatabaseViewModel.swift`
3. `ViewModels/TableBrowserViewModel.swift`
4. `ViewModels/SettingsViewModel.swift`

---

### 6.1 — QueryEditorViewModel (igual que v1 + setResult)

El ViewModel más complejo del proyecto. Adición clave en v2:

```swift
/// Directly injects a pre-computed result without executing SQL.
/// Used by ExerciseDetailView to display the solution when the user taps "See Answer".
func setResult(_ result: QueryResult) {
    queryResult = result
    errorMessage = nil
    executionMessage = nil
}
```

Esto permite que `ExerciseDetailView` muestre el resultado esperado sin re-ejecutar SQL.

---

### 6.2 — DatabaseViewModel (nuevo en v2)

Maneja **exclusivamente** el historial persistente. Separado de `TableBrowserViewModel` porque:

- Las responsabilidades son distintas: tablas vs historial.
- El ciclo de vida es distinto: el historial solo se carga cuando el usuario visita la pestaña Database.
- Facilita el testing: puedes mockear solo el historial sin afectar el browser de tablas.

```swift
@Observable @MainActor
final class DatabaseViewModel {
    var history: [QueryHistoryItem] = []
    var isLoadingHistory: Bool = false
    var historyError: String?

    func loadHistory() async { ... }
    func clearHistory() async { ... }
}
```

---

### 6.3 — TableBrowserViewModel (ampliado en v2)

Además de cargar tablas y su schema, ahora carga `TableSummary`:

```swift
var tableSummaries: [TableSummary] = []

func loadTableSummaries() async {
    // Para cada tabla: consulta columnCount con PRAGMA y rowCount con COUNT(*)
}
```

El `DatabaseView` llama a ambos en `.task`:
```swift
.task {
    await tableBrowserViewModel.loadTables()
    await tableBrowserViewModel.loadTableSummaries()
    await databaseViewModel.loadHistory()
}
```

---

### 6.4 — SettingsViewModel (sin cambios funcionales)

Sigue usando `UserDefaults` para el color de keywords. El patrón de cacheo del `UIColor` explicado en v1 permanece intacto.

---

### Ejercicio Sesión 6
`DatabaseViewModel` y `TableBrowserViewModel` ambos dependen de `DatabaseServiceProtocol`. ¿Podrías combinarlos en uno? ¿Cuáles serían las ventajas y desventajas de esa decisión?

---

## Sesión 7: ExercisesViewModel — Pieza Central del Módulo

### Objetivos
- Entender el ciclo de vida de seeding: verificar → cargar JSON → pre-computar.
- Comprender la validación por output, no por texto SQL.
- Saber cómo se persiste el mejor puntaje.

### Archivos a revisar
1. `ViewModels/ExercisesViewModel.swift`

---

### 7.1 — Diseño de Estado

```swift
// Seeding state
private(set) var seedingBlockIDs: Set<UUID> = []   // En progreso ahora
private(set) var seededBlockIDs:  Set<UUID> = []   // Ya completados esta sesión
private(set) var seedingErrors:   [UUID: String] = [:]

// Resultados esperados (pre-computados)
private(set) var expectedResults: [UUID: QueryResult] = [:]

// Previews de tablas para mostrar al usuario
private(set) var tablePreviewData: [String: QueryResult] = [:]

// Puntuaciones
private(set) var bestScores: [String: Int] = [:]
```

Los Sets `seedingBlockIDs` y `seededBlockIDs` trabajan en conjunto para hacer el seeding **idempotente y concurrency-safe**:

- Si la función se llama dos veces simultáneamente para el mismo bloque, el segundo llamado se descarta inmediatamente (`guard !seedingBlockIDs.contains(block.id)`).
- Si la función se llama una segunda vez para un bloque ya procesado, se descarta instantáneamente (`guard !seededBlockIDs.contains(block.id)`).

---

### 7.2 — El Flujo de seedTablesIfNeeded

```
seedTablesIfNeeded(for block)
  │
  ├── ¿Ya seeded o seeding? → return (guard)
  │
  ├── Marcar como "seeding" (insert en seedingBlockIDs)
  │
  ├── findMissingTables(for block)
  │     └── listTables() → comparar con block.tableNames (case-insensitive)
  │
  ├── Si hay tablas faltantes → runJSON(for block)
  │     ├── Bundle.main.url(forResource: block.jsonFileName, withExtension: "json")
  │     ├── JSONDecoder().decode([String].self, from: data)
  │     └── executeNonQuery/executeQuery por cada statement
  │
  ├── computeExpectedResults(for block)
  │     └── Por cada exercise: executeQuery(exercise.solutionSQL) → cache
  │
  ├── loadTablePreviews(for block)
  │     └── Por cada tableName: getTableData(tableName, limit: 200) → cache
  │
  └── Marcar como "seeded" (remove de seedingBlockIDs, insert en seededBlockIDs)
```

---

### 7.3 — Validación por Output

```swift
func validate(_ userResult: QueryResult, for exercise: Exercise) -> Bool? {
    guard let expected = expectedResults[exercise.id] else { return nil }
    guard userResult.columns == expected.columns else { return false }
    guard userResult.rows.count == expected.rows.count else { return false }
    return zip(userResult.rows, expected.rows).allSatisfy { $0 == $1 }
}
```

`nil` = aún no hay resultado esperado (seeding en progreso)
`false` = columnas o filas no coinciden
`true` = respuesta correcta

**Por qué comparar output y no texto SQL**: `SELECT id FROM Dinosaurs` y `select ID from dinosaurs` son textualmente distintos pero producen el mismo resultado. El sistema acepta cualquier variación sintáctica válida.

---

### 7.4 — Persistencia del Mejor Puntaje

```swift
func recordCompletion(for block: ExerciseBlock, attempts: [ExerciseAttemptRecord]) {
    let correct = attempts.filter(\.wasCorrect).count
    let score = Int((Double(correct) / Double(attempts.count)) * 100)
    let key = block.id.uuidString

    let previous = bestScores[key] ?? -1
    if score > previous {
        bestScores[key] = score
        UserDefaults.standard.set(bestScores, forKey: Self.bestScoresKey)
    }
}
```

**Solo se guarda si mejora**: Un score de 60% no sobreescribe un 80% anterior. Esto incentiva al usuario a reintentar para mejorar su mejor marca.

**`block.id.uuidString` como clave**: El `UUID` del bloque persiste entre sesiones porque se define como `let id = UUID()` en la definición del struct en `ExercisesView`. Al ser `let`, siempre genera el mismo UUID... **¡espera!** En realidad, `let id = UUID()` genera un UUID **diferente cada vez que se compila** a menos que el valor sea constante.

> ⚠️ **Limitación actual**: El UUID de un `ExerciseBlock` cambia si el desarrollador modifica el archivo que lo define. Esto invalidaría los puntajes guardados. En producción, los IDs de bloques deberían ser `UUID(uuidString: "...")` con valores fijos codificados.

---

### Ejercicio Sesión 7
El sistema actualmente almacena `bestScores` en `UserDefaults` como `[String: Int]`. ¿Cómo migrarías esto a `_query_history`? (No lo hagas, solo diseña la solución).

---

## Sesión 8: Pestaña SQL Editor

### Objetivos
- Ver cómo la v2 mantiene el editor igual que la v1 pero añade historial persistente.
- Entender el guardado automático de cada consulta ejecutada.

### Archivos a revisar
1. `Views/QueryEditorView.swift`
2. `Views/SQLTextEditorView.swift`
3. `Views/SQLTextEditorCoordinator.swift`

---

### 8.1 — Guardado Automático en el Historial

La diferencia principal del editor en v2: cada ejecución exitosa (o fallida) se **persiste en SQLite**:

```swift
// En QueryEditorViewModel.executeSQL():
let historyItem = QueryHistoryItem(
    sql: trimmed,
    executedAt: Date(),
    wasSuccessful: true,
    rowsAffected: rowsAffected,
    errorMessage: nil
)
try? await databaseService.saveHistoryItem(historyItem)
```

Nota el `try?`: el fallo al guardar en historial es **no fatal**. Si la operación falla, el usuario no ve ningún error — el resultado de la query se muestra igual.

---

### 8.2 — UIViewRepresentable: El Fix del Warning de UIKit

En versiones anteriores, el editor generaba el warning:
> _"The variant selector cell index number could not be found."_

**Causa raíz**: Asignar `textView.attributedText = ...` reemplaza el `NSTextStorage` completo, haciendo que el tokenizador interno de `UITextInputStringTokenizer` reconstruya sus tablas de forma asíncrona. Si se asigna `selectedRange` inmediatamente después, puede ocurrir antes de que la reconstrucción termine.

**Fix implementado**: Usar `textStorage` directamente en lugar de `attributedText`:

```swift
// ANTES (causaba el warning):
textView.attributedText = SQLSyntaxHighlighter.highlight(text, keywordColor: keywordColor)
textView.selectedRange = NSRange(location: offset, length: 0)

// DESPUÉS (sin warning):
let highlighted = SQLSyntaxHighlighter.highlight(text, keywordColor: keywordColor)
textView.textStorage.beginEditing()
textView.textStorage.setAttributedString(highlighted)
textView.textStorage.endEditing()
// NSLayoutManager notifica al tokenizador sincrónicamente en endEditing()
let safeOffset = min(offset, textView.textStorage.length)
textView.selectedRange = NSRange(location: safeOffset, length: 0)
```

Este patrón aplica en `makeUIView`, `updateUIView`, y `textViewDidChange`.

---

### Ejercicio Sesión 8
Modifica `QueryEditorViewModel` para que el historial en memoria (el que se muestra en la interfaz de forma inmediata) se cargue desde la base de datos al inicializarse, en lugar de estar vacío.

---

## Sesión 9: Pestaña Database

### Objetivos
- Entender la arquitectura multi-nivel de navegación del tab Database.
- Conocer el componente `TableCardView`.

### Archivos a revisar
1. `Views/DatabaseView.swift`
2. `Views/TableCardView.swift`
3. `Views/TableDetailView.swift`
4. `Views/TableListView.swift`

---

### 9.1 — Árbol de Navegación

```
DatabaseView (NavigationStack)
  ├── TableCardView × N    → Destination.table(tableName) → TableDetailView
  ├── QueryHistoryButton   → Destination.queryHistory     → QueryHistoryListView
  └── (desde historial)    → Destination.queryDetail(id)  → HistoryQueryDetailView
```

El enum `Destination` centraliza todos los destinos posibles en el tab:

```swift
enum Destination: Hashable {
    case table(String)
    case queryHistory
    case queryDetail(UUID)
}
```

Un solo `.navigationDestination(for: Destination.self)` maneja los tres casos con un `switch`.

---

### 9.2 — Cuatro Estados en la Sección de Tablas

```
tablesSection:
  ├── errorMessage != nil          → ContentUnavailableView (error)
  ├── isLoading                    → ProgressView
  ├── tableSummaries.isEmpty       → ContentUnavailableView ("No Tables")
  └── tableSummaries no vacío      → LazyVStack con TableCardView × N
```

`LazyVStack` (en lugar de `VStack`) renderiza las cards **perezosamente**: solo las visibles en pantalla se crean. Para listas largas de tablas, esto mejora el rendimiento significativamente.

---

### 9.3 — TableCardView

Un componente de presentación pura (sin lógica de negocio) que muestra:
- Icono de tabla
- Nombre de la tabla
- Número de columnas y filas
- Color de acento del usuario

Recibe un `TableSummary` (ligero) en lugar de un `TableInfo` (pesado).

---

### Ejercicio Sesión 9
`DatabaseView` usa `.navigationBarHidden(true)` y construye su propio header con `Text("Database")`. ¿Por qué no usar `.navigationTitle("Database")`? ¿Qué problema visual resuelve este enfoque?

---

## Sesión 10: Historial Persistente

### Objetivos
- Entender el flujo completo del historial: guardar → listar → ver detalle.
- Conocer las tres vistas del historial.

### Archivos a revisar
1. `Views/QueryHistoryListView.swift`
2. `Views/HistoryQueryCardView.swift`
3. `Views/HistoryQueryDetailView.swift`

---

### 10.1 — QueryHistoryListView

Vista de pantalla completa (oculta la tab bar) que muestra todas las consultas guardadas. Se accede desde `DatabaseView` a través de `NavigationLink(value: Destination.queryHistory)`.

Características:
- **`.toolbar(.hidden, for: .tabBar)`**: Oculta la barra de tabs para maximizar el espacio.
- **Botón "Clear All"**: Llama a `databaseViewModel.clearHistory()` con confirmación.
- **`.task`**: Recarga el historial cada vez que la vista aparece (por si se ejecutó alguna query mientras estaba cerrada).

---

### 10.2 — HistoryQueryCardView

Tarjeta que muestra un `QueryHistoryItem`:
- Icono de éxito/error
- Preview del SQL (truncado)
- Fecha y hora de ejecución
- Número de filas afectadas o mensaje de error

---

### 10.3 — HistoryQueryDetailView

Vista de detalle con el SQL completo con syntax highlighting. El usuario puede:
- Ver la query completa con colores
- Copiar el SQL al portapapeles (con `UIPasteboard`)

---

### Ejercicio Sesión 10
Añade un botón "Cargar en Editor" en `HistoryQueryDetailView` que cargue el SQL de esa query en el editor del tab SQL Editor. ¿Cómo pasarías el texto al `QueryEditorViewModel` correcto desde una vista tan anidada?

---

## Sesión 11: Pestaña Exercises — Diseño General

### Objetivos
- Entender la arquitectura general del módulo de ejercicios.
- Conocer `ExercisesView` y `ExerciseBlockCardView`.

### Archivos a revisar
1. `Views/ExercisesView.swift`
2. `Views/ExerciseBlockCardView.swift`

---

### 11.1 — ExercisesView como Raíz de Navegación

`ExercisesView` gestiona su propio `NavigationStack` con un `NavigationPath` explícito:

```swift
@State private var navigationPath = NavigationPath()

var body: some View {
    NavigationStack(path: $navigationPath) {
        // ...
        .navigationDestination(for: Destination.self) { ... }
    }
}
```

**¿Por qué `NavigationPath` explícito?** Para poder vaciar el stack programáticamente desde vistas hijas:

```swift
// Desde BlockResultsView, vaciar todo el stack:
onDismiss: { navigationPath = NavigationPath() }
```

Si usáramos `NavigationStack` sin `path`, no habría forma de hacer `popToRoot` desde una vista nieta sin propagar el dismiss manualmente por cada nivel.

---

### 11.2 — Tres Estados de las Tarjetas

```swift
@ViewBuilder
private func blockCard(for block: ExerciseBlock) -> some View {
    let seeded = exercisesViewModel.isSeeded(block)
    let seeding = exercisesViewModel.isSeeding(block)
    let error = exercisesViewModel.seedingError(for: block)

    if seeded && error == nil {
        // Tarjeta con NavigationLink — navegación habilitada
        NavigationLink(value: Destination.exerciseDetail(block)) {
            ExerciseBlockCardView(block: block, ..., bestScore: exercisesViewModel.bestScore(for: block))
        }
    } else {
        // Tarjeta bloqueada con overlay
        ExerciseBlockCardView(...)
            .overlay { if seeding { seedingOverlay } else if let error { errorOverlay(message: error) } }
            .allowsHitTesting(false)
    }
}
```

**`allowsHitTesting(false)`**: Deshabilita todos los toques en la vista sin afectar visualmente. El usuario ve la tarjeta pero no puede interactuar con ella mientras se cargan las tablas.

---

### 11.3 — ExerciseBlockCardView con ScoreArcBadge

La tarjeta muestra un pequeño badge con el mejor puntaje cuando el bloque ha sido completado:

```swift
var bestScore: Int? = nil  // nil = nunca completado

// En body:
.overlay(alignment: .bottomTrailing) {
    if let score = bestScore {
        ScoreArcBadge(score: score, color: scoreColor)
            .offset(x: 8, y: 8)
    }
}
```

`ScoreArcBadge` es una vista privada anidada dentro de `ExerciseBlockCardView` — no necesita ser un archivo separado porque solo se usa ahí.

---

### Ejercicio Sesión 11
El seeding de todos los bloques se lanza en `.task` de `ExercisesView`. Si hubiera 20 bloques, ¿se ejecutarían en paralelo o en serie? Analiza el código y justifica tu respuesta.

---

## Sesión 12: ExerciseDetailView — Máquina de Estados

### Objetivos
- Dominar la máquina de estados del editor de ejercicios.
- Entender el sistema de bloqueo del editor y la barra de control.

### Archivos a revisar
1. `Views/ExerciseDetailView.swift`

---

### 12.1 — Variables de Estado

```swift
@State private var currentIndex: Int = 0       // Ejercicio actual (0-based)
@State private var solutionRevealed: Bool = false  // El usuario usó "See Answer"
@State private var editorLocked: Bool = false  // Editor no editable tras Run
@State private var hadIncorrectAttempt: Bool = false  // Tuvo al menos una respuesta mala
@State private var attempts: [ExerciseAttemptRecord] = []  // Para BlockResultsView
@State private var isEditorFocused = false
@State private var showClearButton = false
```

---

### 12.2 — Computed Properties Clave

```swift
private var isCorrect: Bool {
    guard !solutionRevealed else { return false }  // Si reveló solución, no es correcto
    guard let result = queryEditorViewModel.queryResult else { return false }
    return exercisesViewModel.validate(result, for: currentExercise) == true
}

private var isIncorrect: Bool {
    guard !solutionRevealed else { return false }  // Si reveló solución, deja de ser incorrecto
    guard let result = queryEditorViewModel.queryResult else { return false }
    return exercisesViewModel.validate(result, for: currentExercise) == false
}
```

La guarda `!solutionRevealed` en ambas es crítica: cuando se revela la solución, el resultado esperado se inyecta en el editor. `validate()` lo devolvería como `true`, lo que contaría el ejercicio como correcto cuando no lo fue. Esta guarda lo previene.

---

### 12.3 — Barra de Control (State Machine)

```
controlButtons:
  ├── isCorrect || solutionRevealed  → advanceButton ("Next" o "Show Results")
  ├── isIncorrect                    → HStack { showResultButton + incorrectAdvanceButton }
  └── idle / SQL error               → runButton
```

**advanceButton vs incorrectAdvanceButton**: Ambos lideran al último ejercicio con `NavigationLink` hacia `BlockResultsView`. La diferencia es que `incorrectAdvanceButton` se muestra cuando el usuario respondió mal (no cuando respondió bien o reveló la solución).

---

### 12.4 — Bloqueo del Editor

El editor se bloquea tras una ejecución válida:

```swift
// En runButton:
Task {
    await queryEditorViewModel.executeSQL()
    if queryEditorViewModel.queryResult != nil {
        editorLocked = true
        if isIncorrect { hadIncorrectAttempt = true }
    } else if queryEditorViewModel.executionMessage != nil,
              queryEditorViewModel.errorMessage == nil {
        editorLocked = true  // Non-query success (INSERT, etc.)
    }
    // errorMessage != nil → no se bloquea (el usuario puede corregir)
}
```

```swift
// En sqlInputSection:
.opacity(editorLocked ? 0.6 : 1.0)
.allowsHitTesting(!editorLocked)
```

---

### 12.5 — Tarjeta de Instrucciones como Feedback de Veredicto

La tarjeta de instrucciones cambia según el estado, **sin cambiar sus dimensiones**:

```swift
private var instructionsCard: some View {
    ZStack {
        // Fondo cambia según veredicto
        if verdictLabel != nil {
            verdictBackground  // Color.green o Color.red
        } else {
            Color(.secondarySystemGroupedBackground)
        }

        Group {
            if let label = verdictLabel, let color = verdictColor {
                Text(label)  // "Correct" o "Incorrect"
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Instrucciones normales con ícono de bombilla
                HStack { Image(systemName: "lightbulb.fill"); Text(currentExercise.instructions) }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
    }
    .frame(maxWidth: .infinity, minHeight: 60)  // Altura fija siempre
    .clipShape(RoundedRectangle(cornerRadius: 10))
}
```

La clave es que `.frame(minHeight: 60)` está en el **contenedor externo** (el `ZStack`), no en el contenido. Ambas variantes (texto de instrucciones y texto de veredicto) ocupan el mismo espacio.

---

### 12.6 — Reset Limpio al Re-entrar

```swift
.onAppear {
    currentIndex = 0
    attempts = []
    resetExerciseState()  // limpia editor + flags
}
.onChange(of: currentIndex) {
    resetExerciseState()  // limpia editor al avanzar, NO resetea attempts
}
```

Esto garantiza que cada visita al bloque empiece desde el ejercicio 1 con el editor limpio.

---

### Ejercicio Sesión 12
`nextStepButton` limpia el estado del editor **antes** de incrementar `currentIndex`, y no confía en el `onChange(of: currentIndex)` para hacerlo. ¿Por qué este orden importa? ¿Qué problema visual resolvió?

---

## Sesión 13: BlockResultsView — Pantalla de Resultados

### Objetivos
- Entender el diseño del anillo de score animado.
- Aprender el patrón de `onDismiss` para popToRoot.

### Archivos a revisar
1. `Views/BlockResultsView.swift`

---

### 13.1 — El Anillo de Score

```swift
Circle()
    .trim(from: 0, to: CGFloat(score) / 100)  // Arco proporcional al puntaje
    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
    .rotationEffect(.degrees(-90))  // Empieza desde arriba (12 en punto)
    .frame(width: 140, height: 140)
    .animation(.easeOut(duration: 0.8), value: score)
```

`Circle().trim(from:to:)` dibuja un arco. El valor `to` es `score / 100` (de 0.0 a 1.0). La rotación de -90° mueve el punto de inicio al top del círculo.

**`lineCap: .round`**: Los extremos del arco son redondeados, un detalle visual refinado.

---

### 13.2 — popToRoot con onDismiss

En lugar de usar `@Environment(\.dismiss)` (que solo haría pop de un nivel), `BlockResultsView` recibe un callback:

```swift
let onDismiss: () -> Void
// ...
.onTapGesture { onDismiss() }
```

Desde `ExercisesView` se pasa:
```swift
BlockResultsView(
    ...,
    onDismiss: { navigationPath = NavigationPath() }  // Vacía el stack completo
)
```

`NavigationPath()` vacío hace que el `NavigationStack` regrese a su vista raíz en una sola operación, sin animaciones intermedias por cada nivel.

---

### 13.3 — Sin Botón de Regreso

```swift
.navigationBarBackButtonHidden(true)
.toolbar(.hidden, for: .tabBar)
```

La pantalla de resultados es un momento de "pausa celebratoria". Sin botón de regreso, el usuario no puede escapar accidentalmente — debe contemplar sus resultados y después tocar para continuar.

---

### Ejercicio Sesión 13
El anillo anima desde 0 hasta el puntaje final. ¿Cuándo se dispara la animación? ¿Podrías hacer que el anillo se anime desde el puntaje anterior (si el usuario ya tenía un score) hasta el nuevo?

---

## Sesión 14: Carga de Datos con JSON

### Objetivos
- Entender la estructura del JSON de tablas.
- Ver cómo el Bundle y Codable se usan juntos.

### Archivos a revisar
1. `SQLApp/dinosaursInfo.json`
2. `ViewModels/ExercisesViewModel.swift` (runJSON)

---

### 14.1 — Formato del JSON

`dinosaursInfo.json` es un array de strings SQL:

```json
[
    "CREATE TABLE IF NOT EXISTS Dinosaurs (id INTEGER PRIMARY KEY, name TEXT, period TEXT, ...)",
    "INSERT INTO Dinosaurs VALUES (1, 'T-Rex', 'Cretaceous', ...)",
    "INSERT INTO Dinosaurs VALUES (2, 'Triceratops', 'Cretaceous', ...)",
    ...
]
```

**¿Por qué un array de strings y no un JSON estructurado?** Simplicidad. Para poblar una base de datos SQLite, el SQL directo es el formato más natural. Un JSON estructurado (con objetos que representan tablas y filas) requeriría un serializador adicional.

---

### 14.2 — Carga desde Bundle

```swift
private func runJSON(for block: ExerciseBlock) async throws {
    guard let url = Bundle.main.url(
        forResource: block.jsonFileName,  // "dinosaursInfo"
        withExtension: "json"
    ) else {
        throw SeedingError.jsonFileNotFound(block.jsonFileName)
    }

    let data = try Data(contentsOf: url)
    let statements = try JSONDecoder().decode([String].self, from: data)

    for sql in statements {
        // Ejecutar cada statement
    }
}
```

`Bundle.main.url(forResource:withExtension:)` busca el archivo en los recursos compilados de la app. Si el archivo no está incluido en el target, devuelve `nil` y se lanza un error claro (`SeedingError.jsonFileNotFound`).

---

### 14.3 — Adición de Nuevos Bloques

Para añadir un nuevo bloque de ejercicios (ej. "Planets"):

1. Crear `planetsInfo.json` con los statements SQL y añadirlo al target en Xcode.
2. Crear los 5 `Exercise` con su `solutionSQL`.
3. Añadir un `ExerciseBlock(imageName:, jsonFileName: "planetsInfo", tableNames: ["Planets"], exercises: [...])` al array en `ExercisesView`.

No se necesita modificar ningún ViewModel ni servicio.

---

### Ejercicio Sesión 14
¿Por qué se usa `CREATE TABLE IF NOT EXISTS` en el JSON y no simplemente `CREATE TABLE`? ¿Qué pasaría si el usuario borrara una tabla de ejercicios desde el SQL Editor?

---

## Sesión 15: Navegación por Valores en SwiftUI

### Objetivos
- Dominar el patrón de navegación basada en valores.
- Entender cuándo usar `NavigationPath` vs `NavigationStack` simple.

### Archivos a revisar
1. `Views/DatabaseView.swift` (Destination enum + navigationDestination)
2. `Views/ExercisesView.swift` (NavigationPath + popToRoot)

---

### 15.1 — El Patrón Destination Enum

Cada tab que tiene `NavigationStack` define un enum interno `Destination`:

```swift
// DatabaseView
enum Destination: Hashable {
    case table(String)
    case queryHistory
    case queryDetail(UUID)
}

// ExercisesView
enum Destination: Hashable {
    case exerciseDetail(ExerciseBlock)
    case blockResults(ExerciseBlock, [ExerciseAttemptRecord])
}
```

Ventajas:
- **Tipo seguro**: No puedes navegar a un destino que no existe.
- **Un solo `navigationDestination`**: Cubre todos los destinos con un `switch`.
- **Testeable**: Puedes verificar qué destinos están definidos sin ejecutar la app.
- **Deep linking futuro**: El path del NavigationStack puede codificarse/decodificarse.

---

### 15.2 — NavigationPath Explícito vs Implícito

```swift
// Implícito (NavigationStack sin path):
NavigationStack {
    // El stack solo se puede manipular con NavigationLink y dismiss()
}

// Explícito (con NavigationPath):
@State private var path = NavigationPath()
NavigationStack(path: $path) {
    // Puedes manipular el stack directamente:
    path.removeLast()              // Pop un nivel
    path = NavigationPath()        // Pop to root
    path.append(someDestination)   // Push programáticamente
}
```

`ExercisesView` usa el path explícito para el popToRoot desde `BlockResultsView`. `DatabaseView` podría usar uno simple, pero si en el futuro se necesita navegar programáticamente, ya estaría preparado.

---

### 15.3 — NavigationLink con Valor vs con Destino

```swift
// ANTIGUO — NavigationLink con destino directo (deprecated en iOS 16+)
NavigationLink(destination: SomeView()) { Text("Ir") }

// MODERNO — NavigationLink con valor (iOS 16+)
NavigationLink(value: Destination.table("Dinosaurs")) { Text("Ver Dinosaurs") }
// La vista se construye en .navigationDestination
```

El enfoque moderno separa la **intención de navegar** (qué dato) de la **construcción de la vista destino** (cómo mostrarlo). Esto facilita el deep linking y reduce el acoplamiento.

---

### Ejercicio Sesión 15
¿Qué sucede si defines dos `.navigationDestination(for: Destination.self)` en el mismo `NavigationStack`? ¿Cuál prevalece? Busca en la documentación de Apple.

---

## Sesión 16: UIViewRepresentable y Syntax Highlighting (v2)

### Objetivos
- Ver los cambios de la v2 respecto al coordinator pattern.
- Entender el fix del warning de UIKit.

### Archivos a revisar
1. `Views/SQLTextEditorView.swift`
2. `Views/SQLTextEditorCoordinator.swift`
3. `Services/SQLSyntaxHighlighter.swift`

---

### 16.1 — El Problema de los Dos Ciclos

En `ExerciseDetailView`, el editor se resetea programáticamente cuando el usuario avanza al siguiente ejercicio:

```swift
queryEditorViewModel.sqlText = ""
queryEditorViewModel.clearResults()
```

Esto dispara `updateUIView` en `SQLTextEditorView`, que detecta `textView.text != text` y actualiza el `textStorage`. Si el reseteo ocurre en el mismo ciclo de render que la transición de ejercicio, puede haber una ventana donde el `textStorage` está siendo actualizado mientras UIKit está procesando la animación. El fix del `textStorage.beginEditing()` también ayuda aquí.

---

### 16.2 — Resumen del Pattern Coordinator

```
Flujo SwiftUI → UIKit:
  text binding cambia externamente
  → SwiftUI llama updateUIView
  → coordinator.isUpdating = true
  → textStorage.setAttributedString(...)
  → selectedRange ajustado
  → coordinator.isUpdating = false

Flujo UIKit → SwiftUI:
  usuario escribe en teclado
  → UITextView llama textViewDidChange al coordinator
  → guard !isUpdating (evita re-entrada)
  → autoUppercase si es boundary char
  → text.wrappedValue = currentText (notifica SwiftUI)
  → textStorage.setAttributedString(highlighted)
  → selectedRange ajustado
```

---

### Ejercicio Sesión 16
En `textViewDidChange`, `cursorOffset` se captura **antes** de `autoUppercaseLastKeyword`. ¿Por qué importa este orden? ¿Qué podría pasar si se capturara después de la mutación del string?

---

## Sesión 17: Persistencia — UserDefaults, SQLite y Migración

### Objetivos
- Ver todos los mecanismos de persistencia de la app en conjunto.
- Entender la estrategia de migración de archivos.

### Archivos a revisar
1. `ViewModels/SettingsViewModel.swift`
2. `SQLAppApp.swift`

---

### 17.1 — Mapa Completo de Persistencia

| Dato | Mecanismo | Clave / Archivo |
|------|-----------|-----------------|
| Tablas del usuario | SQLite | `user_database.sqlite` |
| Historial de queries | SQLite | `_query_history` (en user DB) |
| Color de keywords | UserDefaults | `"sqlKeywordColorHex"` |
| Tablas de ejercicios | SQLite | `app_database.sqlite` |
| Mejor puntaje por bloque | UserDefaults | `"exerciseBlockBestScores"` |
| Tablas pinneadas | UserDefaults | (en TableBrowserViewModel) |

---

### 17.2 — UserDefaults: Qué Usar y Qué Evitar

```swift
// Correcto: Datos pequeños, simples, de preferencias
UserDefaults.standard.set("#FF6B35", forKey: "sqlKeywordColorHex")
UserDefaults.standard.set(["uuid1": 80, "uuid2": 100], forKey: "exerciseBlockBestScores")

// Incorrecto: Datos grandes, frecuentes, o estructurados
// UserDefaults.standard.set(queryHistoryItems, forKey: "history")  // ← No hacer esto
```

UserDefaults **no es una base de datos**. Para el historial de queries (que puede tener miles de registros), SQLite es la elección correcta.

---

### 17.3 — Migración sin Estado

La migración de `SQLApp.sqlite` → `user_database.sqlite` es un `static func`:

```swift
private static func migrateLegacyDatabaseIfNeeded()
```

`static` porque no necesita acceder a `self` (ninguna propiedad del `App`). Se llama una vez en `init()` y hace su trabajo silenciosamente. Si el archivo legado no existe (instalación nueva), no hace nada. Si ambos existen (migración ya hecha), no hace nada.

---

### Ejercicio Sesión 17
Si la app tuviera que migrar de un esquema de `_query_history` v1 (sin la columna `error_message`) a v2 (con ella), ¿cómo harías esa migración? Diseña el código que se ejecutaría en el `init()` de `SQLiteDatabaseService`.

---

## Sesión 18: Concurrencia — async/await, MainActor y DispatchQueue

### Objetivos
- Ver cómo fluyen los datos entre hilos en toda la app v2.
- Entender por qué todos los ViewModels son `@MainActor`.

### Archivos relevantes
Transversal — todos los ViewModels y el servicio.

---

### 18.1 — La Regla de MainActor

Todos los ViewModels tienen `@MainActor`:

```swift
@Observable @MainActor
final class ExercisesViewModel { ... }
```

**¿Por qué?** Las propiedades de los ViewModels se leen directamente por las vistas de SwiftUI, que deben actualizarse en el hilo principal. Al decorar el ViewModel con `@MainActor`, Swift garantiza que todas sus propiedades se lean y escriban en el hilo principal.

**¿No bloquea el hilo principal?** No, porque las funciones `async` pueden suspenderse. Cuando se llama `try await databaseService.executeQuery(...)`, el hilo principal queda libre mientras el servicio trabaja en background. Cuando el resultado llega, el `await` retorna en el MainActor.

---

### 18.2 — El Flujo Completo de una Consulta de Ejercicio

```
ExerciseDetailView (MainActor, UI Thread)
  └── runButton toca → Task { await queryEditorViewModel.executeSQL() }

QueryEditorViewModel (MainActor)
  ├── isExecuting = true              → UI muestra spinner
  ├── try await databaseService.executeQuery(sql)  ← SUSPENDE aquí
  │
  └── ... (el MainActor está libre mientras tanto) ...
  
SQLiteDatabaseService (DispatchQueue - background)
  ├── withCheckedThrowingContinuation
  │   └── queue.async {
  │         sqlite3_prepare_v2 / sqlite3_step / sqlite3_finalize
  │         continuation.resume(returning: QueryResult)
  │       }
  └── El DispatchQueue llama a continuation.resume()
  
→ Swift retoma QueryEditorViewModel en el MainActor
  ├── queryResult = result            → UI muestra la tabla
  └── isExecuting = false             → UI oculta spinner
```

---

### 18.3 — ExercisesViewModel y el Seeding Paralelo (o en Serie)

```swift
// En ExercisesView.task:
for block in exerciseBlocks {
    await exercisesViewModel.seedTablesIfNeeded(for: block)
}
```

El `for...await` es **secuencial** — espera a que el primero termine antes de iniciar el segundo. Para paralelizar:

```swift
await withTaskGroup(of: Void.self) { group in
    for block in exerciseBlocks {
        group.addTask {
            await exercisesViewModel.seedTablesIfNeeded(for: block)
        }
    }
}
```

Sin embargo, el seeding secuencial actual tiene una ventaja: las escrituras en SQLite no compiten entre sí (el `DispatchQueue` serializa el acceso, pero no tiene sentido lanzar múltiples writes simultáneos desde el MainActor hacia la misma cola).

---

### Ejercicio Sesión 18
Un `Task { }` creado dentro de un contexto `@MainActor` hereda ese actor. Pero `ExercisesViewModel` es `@MainActor` y llama a `databaseService.executeQuery` con `await`. ¿En qué hilo se ejecuta realmente el SQL de SQLite? Traza el camino completo.

---

## Sesión 19: Testing y Arquitectura Testeable

### Objetivos
- Crear un Mock del servicio que funcione con los ViewModels de v2.
- Identificar qué testear en el módulo de ejercicios.

### Archivos relevantes
Transversal — todos los ViewModels.

---

### 19.1 — MockDatabaseService para v2

```swift
final class MockDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {

    var queryResultToReturn: QueryResult?
    var errorToThrow: Error?
    var tablesToReturn: [String] = []
    var historyToReturn: [QueryHistoryItem] = []

    // v1 methods
    nonisolated func executeQuery(_ sql: String) async throws -> QueryResult {
        if let error = errorToThrow { throw error }
        return queryResultToReturn ?? QueryResult(columns: [], rows: [])
    }
    nonisolated func executeNonQuery(_ sql: String) async throws -> Int { return 0 }
    nonisolated func listTables() async throws -> [String] { tablesToReturn }
    nonisolated func getTableInfo(_ tableName: String) async throws -> TableInfo {
        TableInfo(name: tableName, columns: [])
    }
    nonisolated func getTableData(_ tableName: String, limit: Int) async throws -> QueryResult {
        queryResultToReturn ?? QueryResult(columns: [], rows: [])
    }

    // v2 history methods
    nonisolated func saveHistoryItem(_ item: QueryHistoryItem) async throws {}
    nonisolated func loadHistory() async throws -> [QueryHistoryItem] { historyToReturn }
    nonisolated func clearHistory() async throws { historyToReturn = [] }
}
```

---

### 19.2 — Tests para ExercisesViewModel

```swift
@Test func seedingSkippedForAlreadySeededBlock() async {
    let mock = MockDatabaseService()
    mock.tablesToReturn = ["Dinosaurs"]  // La tabla ya existe
    let vm = await ExercisesViewModel(databaseService: mock)
    let block = makeTestBlock()  // ExerciseBlock de prueba

    await vm.seedTablesIfNeeded(for: block)
    await vm.seedTablesIfNeeded(for: block)  // Segunda llamada

    // El JSON no debe haberse ejecutado porque la tabla ya existía
    // Verificar que seededBlockIDs contiene el bloque
    let isSeeded = await vm.isSeeded(block)
    #expect(isSeeded == true)
}

@Test func validateReturnsTrueForMatchingOutput() async {
    let mock = MockDatabaseService()
    let expected = QueryResult(columns: ["name"], rows: [["T-Rex"]])
    mock.queryResultToReturn = expected
    let vm = await ExercisesViewModel(databaseService: mock)
    let exercise = Exercise(title: "Test", instructions: "...", solutionSQL: "SELECT name FROM Dinosaurs")

    // Simular que el resultado esperado ya fue pre-computado
    // ...

    let userResult = QueryResult(columns: ["name"], rows: [["T-Rex"]])
    let isCorrect = await vm.validate(userResult, for: exercise)
    #expect(isCorrect == true)
}
```

---

### 19.3 — Tests de Integración para el Servicio

```swift
@Test func historyPersistsAcrossServiceInstances() async throws {
    let tempPath = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString + ".sqlite").path
    let item = QueryHistoryItem(sql: "SELECT 1", executedAt: Date(), ...)

    // Crear, guardar, destruir
    let service1 = SQLiteDatabaseService(databaseName: tempPath, enableHistory: true)
    try await service1.saveHistoryItem(item)

    // Crear nueva instancia con el mismo archivo
    let service2 = SQLiteDatabaseService(databaseName: tempPath, enableHistory: true)
    let loaded = try await service2.loadHistory()

    #expect(loaded.count == 1)
    #expect(loaded.first?.sql == "SELECT 1")
}
```

---

### Ejercicio Sesión 19
Escribe un test que verifique que `recordCompletion` solo actualiza el puntaje cuando el nuevo es mayor. Usa `MockDatabaseService` y crea un `ExercisesViewModel` en el test.

---

## Sesión 20: Resumen de Buenas Prácticas y Extensibilidad

### Objetivos
- Consolidar todos los patrones aprendidos.
- Identificar las limitaciones actuales y cómo superarlas.
- Planear futuras extensiones.

---

### 20.1 — Buenas Prácticas Implementadas

#### Arquitectura y Diseño
- ✅ **MVVM estricto**: Las vistas solo leen propiedades de los ViewModels, nunca acceden al servicio directamente.
- ✅ **Un tipo por archivo**: Cada struct/class/enum vive en su propio archivo.
- ✅ **Dependency Injection**: Los ViewModels reciben `any DatabaseServiceProtocol`, nunca la clase concreta.
- ✅ **Separación de concerns**: `DatabaseViewModel` maneja historial, `TableBrowserViewModel` maneja tablas. Son independientes.
- ✅ **Modelos inmutables**: Todos los modelos son `struct` con propiedades `let`.

#### Concurrencia
- ✅ **`@Observable` + `@MainActor`**: Los ViewModels se actualizan en el hilo principal automáticamente.
- ✅ **`async/await`** en lugar de completion handlers: Código lineal, sin callback hell.
- ✅ **`Sendable`** en modelos y en el protocolo: El compilador verifica la seguridad entre actores.
- ✅ **Serial `DispatchQueue`** para SQLite: Acceso serializado sin data races.

#### UI y UX
- ✅ **Navegación por valores**: `NavigationLink(value:)` con enums `Hashable` tipados.
- ✅ **`NavigationPath` explícito**: Permite popToRoot programático desde cualquier nivel.
- ✅ **Estado de 4 variantes**: Loading / Empty / Error / Content en todas las vistas de lista.
- ✅ **Feedback háptico**: `.sensoryFeedback` para éxito y error en el editor.
- ✅ **Animaciones declarativas**: `.animation(.easeInOut, value:)` para transiciones de estado.

#### Patrones Específicos del Módulo de Ejercicios
- ✅ **Seeding idempotente**: Guards con `seedingBlockIDs`/`seededBlockIDs` evitan duplicados y race conditions.
- ✅ **Validación por output**: Acepta cualquier query que produzca el resultado correcto.
- ✅ **Editor lock state machine**: `editorLocked`, `solutionRevealed`, `hadIncorrectAttempt` definen 4 estados sin ambigüedad.
- ✅ **Puntaje "best score"**: Solo se sobreescribe si mejora.

---

### 20.2 — Trade-offs Aceptados

| Trade-off | Justificación |
|-----------|---------------|
| `@unchecked Sendable` en el servicio | `OpaquePointer` (SQLite C API) no conforma `Sendable`. Un `Actor` sería más seguro pero incompatible con el puntero C. |
| `nonisolated(unsafe) var db` | El acceso está serializado por el `DispatchQueue`, no por el compilador. Correcto pero no verificado. |
| UUID dinámico en `ExerciseBlock` | Los `let id = UUID()` generan IDs diferentes si se modifica la definición. Los `bestScores` se invalidarían. En producción, usar UUIDs fijos. |
| Seeding secuencial | Más simple que paralelo. Con pocos bloques el impacto es mínimo. |
| `try?` al guardar historial | El fallo de persistencia es no-fatal. El usuario ve sus resultados igual. |

---

### 20.3 — Limitaciones y Mejoras Futuras

#### Módulo de Ejercicios
- **Más bloques**: Añadir JSON + `ExerciseBlock` en `ExercisesView`. Zero changes al servicio.
- **Dificultad progresiva**: Añadir una propiedad `difficulty: Int` a `ExerciseBlock` y filtrar/ordenar.
- **UUID persistente para bloques**: Cambiar `let id = UUID()` por `let id: UUID` con valores fijos en el init.
- **Sincronización de puntajes con iCloud**: Mover `bestScores` de `UserDefaults` a `NSUbiquitousKeyValueStore`.

#### Editor SQL
- **CTEs y comentarios**: El detector de SELECT por prefijo falla con `WITH cte AS (...)` y `-- comment\nSELECT`. Un tokenizador básico lo resolvería.
- **Autocompletado**: Un menu de autocompletado con nombres de tablas y columnas.
- **Multi-statement**: Ejecutar múltiples statements separados por `;`.

#### Base de Datos y Persistencia
- **Exportación a CSV/JSON**: Un `ExportService` con `ShareLink` de SwiftUI.
- **Importación desde URL**: URLSession + JSONDecoder para cargar datos desde una API.
- **Backup a iCloud Drive**: `FileManager` + `NSFileCoordinator` para sincronizar la base de datos.

---

### 20.4 — Cómo Añadir un Nuevo Tab

Para añadir una quinta pestaña (ej. "Schemas") siguiendo la arquitectura:

1. **Crear el ViewModel** en `ViewModels/SchemasViewModel.swift`:
   ```swift
   @Observable @MainActor
   final class SchemasViewModel {
       private let databaseService: any DatabaseServiceProtocol
       init(databaseService: any DatabaseServiceProtocol) { ... }
   }
   ```

2. **Crear la vista** en `Views/SchemasView.swift`.

3. **Añadir el ViewModel en `ContentView`**:
   ```swift
   @State private var schemasVM: SchemasViewModel
   // En init():
   self._schemasVM = State(initialValue: SchemasViewModel(databaseService: userDatabaseService))
   ```

4. **Añadir el Tab en `ContentView.body`**:
   ```swift
   Tab("Schemas", systemImage: "doc.text.magnifyingglass") {
       SchemasView(viewModel: schemasVM, settingsViewModel: settingsVM)
   }
   ```

---

### Ejercicio Final Sesión 20
Diseña (sin implementar) el módulo de "Exportar Resultados":
- **a)** ¿Qué protocolo/servicio nuevo necesitas? ¿Dónde vive?
- **b)** ¿Qué ViewModel se modifica o crea?
- **c)** ¿Cómo se presenta al usuario (botón en toolbar, sheet, share sheet)?
- **d)** ¿Cómo manejas errores durante la exportación?
- **e)** ¿A qué bases de datos accede? ¿Solo a la del usuario o también a la de ejercicios?
- **f)** Dibuja el diagrama de flujo completo desde que el usuario toca el botón hasta que el archivo aparece en el share sheet.

---

## Apéndice — Mapa de Archivos del Proyecto

```
SQLApp/
├── SQLAppApp.swift              → Punto de entrada. Crea los 2 servicios. Migra legado.
├── ContentView.swift            → Raíz de composición. 4 tabs. 5 ViewModels.
│
├── Models/
│   ├── ColumnInfo.swift         → Columna de una tabla (nombre, tipo, constraints)
│   ├── DatabaseError.swift      → Enum de errores del servicio
│   ├── DetailTab.swift          → Enum .structure / .data para el picker de TableDetailView
│   ├── ExecutionStatus.swift    → Enum .success(Int) / .error(Int) para hápticos
│   ├── Exercise.swift           → Un ejercicio individual (título, instrucciones, solutionSQL)
│   ├── ExerciseAttemptRecord.swift → Resultado de un intento (correcto/incorrecto + query usada)
│   ├── ExerciseBlock.swift      → Bloque de 5 ejercicios con sus tablas y JSON
│   ├── HexColor.swift           → Namespace: conversión UIColor ↔ hex string
│   ├── PinnedTable.swift        → Tabla anclada al dashboard
│   ├── PinnedTableDisplayMode.swift → Modo de visualización de tabla anclada
│   ├── QueryHistoryItem.swift   → Query ejecutada con timestamp y resultado
│   ├── QueryResult.swift        → Resultado de SELECT: columnas + filas
│   ├── SQLKeywords.swift        → Namespace: Set de keywords SQLite para highlighting
│   ├── TableInfo.swift          → Schema completo de una tabla
│   └── TableSummary.swift       → Resumen ligero: nombre + columnCount + rowCount
│
├── Services/
│   ├── DatabaseServiceProtocol.swift  → 8 métodos: 5 de datos + 3 de historial
│   ├── SQLiteDatabaseService.swift    → Implementación con SQLite3 C API
│   └── SQLSyntaxHighlighter.swift     → Namespace: highlighting + auto-uppercase
│
├── ViewModels/
│   ├── DatabaseViewModel.swift        → Historial persistente (load + clear)
│   ├── ExercisesViewModel.swift       → Seeding + validación + puntajes
│   ├── QueryEditorViewModel.swift     → Editor SQL (ejecutar, historial, estado)
│   ├── SettingsViewModel.swift        → Color de keywords (UserDefaults)
│   └── TableBrowserViewModel.swift    → Lista de tablas + schema + summaries
│
├── Views/
│   ├── BlockResultsView.swift         → Pantalla de resultados post-bloque
│   ├── DatabaseView.swift             → Tab Database (tablas + historial button)
│   ├── ExerciseBlockCardView.swift    → Tarjeta de bloque con score badge
│   ├── ExerciseDetailView.swift       → Editor de ejercicios (state machine)
│   ├── ExercisesView.swift            → Tab Exercises (lista de bloques)
│   ├── HistoryQueryCardView.swift     → Tarjeta de item de historial
│   ├── HistoryQueryDetailView.swift   → Detalle de query histórica
│   ├── QueryEditorView.swift          → Tab SQL Editor
│   ├── QueryHistoryListView.swift     → Lista fullscreen de historial
│   ├── ResultsTableView.swift         → Tabla de resultados (Grid scrolleable)
│   ├── SettingsView.swift             → Tab Settings (color picker)
│   ├── SQLTextEditorCoordinator.swift → Delegate UITextView → SwiftUI
│   ├── SQLTextEditorView.swift        → UIViewRepresentable del editor
│   ├── TableCardView.swift            → Tarjeta de tabla con summary
│   ├── TableDetailView.swift          → Schema + datos de una tabla
│   └── TableListView.swift            → Lista de tablas (dentro de TableBrowserVM)
│
├── dinosaursInfo.json           → Array de SQL strings para tabla Dinosaurs
└── CourseNotes.swift            → Documentación de la versión 1 (10 sesiones)
```

---

*Documento generado para SQLApp v2 — 18 de Marzo 2026*
