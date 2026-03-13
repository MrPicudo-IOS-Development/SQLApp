// MARK: - ============================================================
// MARK:   CURSO: Desarrollo y Mantenimiento de SQLApp
// MARK:   Material de estudio — 10 sesiones
// MARK: - ============================================================
//
// Este archivo contiene notas de curso organizadas en 10 sesiones.
// Cada sesión incluye objetivos, archivos a revisar, conceptos clave
// y ejercicios sugeridos.
//
// El objetivo es que un estudiante universitario pueda:
// 1. Entender la aplicación completa y su arquitectura.
// 2. Mantenerla y corregir bugs de manera autónoma.
// 3. Agregarle funcionalidades nuevas siguiendo los patrones existentes.
// 4. Escalarla con mejores mecanismos de persistencia y servicios.
//
// ============================================================



// MARK: - SESIÓN 1: Visión General y Punto de Entrada
// ============================================================
//
// OBJETIVOS:
// - Comprender la estructura general del proyecto y por qué está organizada así.
// - Identificar el punto de entrada de la aplicación.
// - Entender qué es la inyección de dependencias y por qué se usa.
//
// ARCHIVOS A REVISAR (en orden):
// 1. SQLAppApp.swift
// 2. ContentView.swift
// 3. Services/DatabaseServiceProtocol.swift
//
// ────────────────────────────────────────────────────────────
//
// 1.1 — ESTRUCTURA DEL PROYECTO
//
// El proyecto sigue la arquitectura MVVM (Model-View-ViewModel) con una
// separación estricta en carpetas:
//
//   Models/        → Estructuras de datos puras (sin lógica de negocio).
//   Services/      → Lógica de acceso a datos y utilidades (no dependen de UI).
//   ViewModels/    → Clases @Observable que conectan los datos con las vistas.
//   Views/         → Componentes de SwiftUI que muestran la interfaz de usuario.
//
// REGLA FUNDAMENTAL: Un archivo = Un tipo (clase, struct o enum).
// Esto facilita la búsqueda de código y evita archivos enormes.
//
// ¿POR QUÉ MVVM?
// - La View solo se encarga de mostrar datos y capturar acciones del usuario.
// - El ViewModel contiene la lógica: qué hacer cuando el usuario toca "Run",
//   cómo formatear los resultados, cuándo mostrar un error, etc.
// - El Model son los datos puros: un QueryResult, un TableInfo, un error.
// - Esto significa que puedes cambiar toda la UI sin tocar la lógica,
//   o cambiar la base de datos sin tocar la UI.
//
// ────────────────────────────────────────────────────────────
//
// 1.2 — PUNTO DE ENTRADA: SQLAppApp.swift
//
// La app arranca aquí. Solo hace dos cosas:
//
//   1. Crea UNA instancia del servicio de base de datos:
//      private let databaseService: any DatabaseServiceProtocol = SQLiteDatabaseService()
//
//   2. La inyecta en ContentView:
//      ContentView(databaseService: databaseService)
//
// La palabra clave `any` indica que la variable almacena "cualquier tipo que
// cumpla con DatabaseServiceProtocol". Esto se llama TYPE ERASURE y es lo
// que permite intercambiar implementaciones. Por ejemplo, en tests podrías
// crear un `MockDatabaseService` que implemente el mismo protocolo pero
// devuelva datos falsos, sin tocar ni una línea de UI.
//
// ────────────────────────────────────────────────────────────
//
// 1.3 — COMPOSICIÓN RAÍZ: ContentView.swift
//
// ContentView es la "raíz de composición" — el lugar donde se crean TODOS
// los ViewModels y se distribuyen a las vistas que los necesitan.
//
//   @State private var queryEditorVM: QueryEditorViewModel
//   @State private var tableBrowserVM: TableBrowserViewModel
//   @State private var settingsVM = SettingsViewModel()
//
// ¿POR QUÉ @State PARA LOS VIEWMODELS?
//
// En SwiftUI, @State le dice al framework: "este dato me pertenece a mí,
// consérvalo mientras yo exista". Si no usáramos @State, cada vez que
// SwiftUI re-evaluara el body de ContentView (algo que ocurre con
// frecuencia), se crearían ViewModels NUEVOS y perderíamos todo el estado:
// el texto SQL que escribió el usuario, los resultados, el historial, etc.
//
// @State garantiza que los ViewModels sobreviven a las re-evaluaciones
// del body y a los cambios de tab.
//
// Los ViewModels que requieren el servicio de base de datos se crean en
// el init() usando la sintaxis State(initialValue:) porque necesitan
// recibir el parámetro databaseService:
//
//   init(databaseService: any DatabaseServiceProtocol) {
//       self._queryEditorVM = State(
//           initialValue: QueryEditorViewModel(databaseService: databaseService)
//       )
//   }
//
// settingsVM no necesita el servicio, así que se inicializa directamente
// con su valor por defecto.
//
// ────────────────────────────────────────────────────────────
//
// 1.4 — INYECCIÓN DE DEPENDENCIAS
//
// La inyección de dependencias es un principio del SOLID (la "D": Dependency
// Inversion Principle). Dice: "depende de abstracciones, no de implementaciones
// concretas".
//
// En la práctica esto significa que:
// - Los ViewModels reciben `any DatabaseServiceProtocol` (la abstracción).
// - Nunca escriben `SQLiteDatabaseService` directamente (la implementación).
// - Si mañana quisiéramos usar Core Data, solo crearíamos una nueva clase
//   `CoreDataDatabaseService` que implemente el mismo protocolo.
//
// ¿POR QUÉ NO @Environment O @EnvironmentObject?
//
// Podríamos haber inyectado el servicio vía el Environment de SwiftUI,
// pero el enfoque explícito (pasarlo como parámetro) tiene ventajas:
// - Es más fácil de rastrear: ves en el init() exactamente de dónde viene.
// - No hay "magia": si olvidas pasarlo, el compilador te avisa.
// - Para tests, no necesitas configurar un Environment falso.
//
// La desventaja es verbosidad: hay que pasar settingsViewModel manualmente
// a través de ContentView → TableListView → TableDetailView. En proyectos
// más grandes, el Environment puede ser más práctico.
//
// EJERCICIO SESIÓN 1:
// Dibuja un diagrama de las dependencias de la app:
// SQLAppApp → ContentView → [QueryEditorView, TableListView, SettingsView]
// ¿Qué ViewModel recibe cada vista? ¿Cuáles se comparten entre tabs?




// MARK: - SESIÓN 2: Modelos de Datos
// ============================================================
//
// OBJETIVOS:
// - Entender cada modelo y por qué existe como tipo separado.
// - Comprender los protocolos Sendable e Identifiable.
// - Conocer el patrón "enum sin casos" (caseless enum) como namespace.
//
// ARCHIVOS A REVISAR (en orden):
// 1. Models/DatabaseError.swift
// 2. Models/QueryResult.swift
// 3. Models/TableInfo.swift
// 4. Models/ColumnInfo.swift
// 5. Models/QueryHistoryItem.swift
// 6. Models/DetailTab.swift
// 7. Models/ExecutionStatus.swift
// 8. Models/SQLKeywords.swift
// 9. Models/HexColor.swift
//
// ────────────────────────────────────────────────────────────
//
// 2.1 — MODELOS DE DOMINIO (DatabaseError, QueryResult, TableInfo, ColumnInfo)
//
// Estos representan los datos del negocio: errores de BD, resultados de
// consultas, información de tablas y columnas.
//
// Todos son STRUCTS (excepto DatabaseError que es enum). ¿Por qué structs?
// - Son tipos por valor: copiarlos es seguro y barato.
// - No tienen identidad (dos QueryResult con los mismos datos son iguales).
// - Swift los optimiza para vivir en el stack, no en el heap.
//
// Todos conforman SENDABLE:
//
//   struct QueryResult: Sendable { ... }
//
// Sendable es un protocolo que le dice al compilador: "este tipo es seguro
// para pasar entre hilos (threads) o actores". Como nuestros modelos son
// structs con propiedades que también son Sendable (String, Int, Bool, Array
// de Sendable), el compilador puede verificar esto automáticamente.
//
// Esto es CRÍTICO porque los datos viajan desde el hilo de la base de datos
// (un DispatchQueue en background) hasta el hilo principal (MainActor)
// donde SwiftUI los muestra. Sin Sendable, el compilador no puede garantizar
// que no habrá data races.
//
// ────────────────────────────────────────────────────────────
//
// 2.2 — MODELOS DE UI (DetailTab, ExecutionStatus)
//
// Estos modelos existen solo para la interfaz:
//
// - DetailTab: Un enum con dos casos (.structure, .data) para el picker
//   en TableDetailView. Usa CaseIterable para generar las opciones del
//   picker automáticamente con ForEach(DetailTab.allCases).
//
// - ExecutionStatus: Un enum con valores asociados (.success(Int), .error(Int))
//   que sirve como TRIGGER para el feedback háptico.
//
//   ¿Por qué el Int asociado?
//   Porque .sensoryFeedback solo se dispara cuando el valor CAMBIA.
//   Si ejecutas dos SELECTs exitosos seguidos, ambos serían .success,
//   y SwiftUI no detectaría cambio. El contador (feedbackCounter) garantiza
//   que .success(1) ≠ .success(2), disparando el háptico cada vez.
//
// ────────────────────────────────────────────────────────────
//
// 2.3 — NAMESPACES: CASELESS ENUMS (SQLKeywords, HexColor)
//
// Swift no tiene un keyword "namespace" como C++. La convención es usar
// un enum sin casos (caseless enum):
//
//   enum SQLKeywords {
//       static let all: Set<String> = ["SELECT", "FROM", ...]
//   }
//
// ¿Por qué enum y no struct?
// Porque un enum sin casos NO SE PUEDE INSTANCIAR. Nadie puede escribir
// `let x = SQLKeywords()` por accidente. Es puramente un contenedor de
// constantes y funciones estáticas. Si fuera struct, podrías crear una
// instancia vacía que no tiene sentido.
//
// ¿Por qué Set y no Array para SQLKeywords.all?
// Porque la operación principal es buscar si una palabra está en la lista
// (contains). Un Set hace esto en O(1) — tiempo constante, sin importar
// cuántas palabras haya. Un Array lo haría en O(n) — revisando una por una.
// Como esta búsqueda ocurre en CADA tecla que presiona el usuario, la
// diferencia de rendimiento es significativa.
//
// EJERCICIO SESIÓN 2:
// Agrega un nuevo modelo `ExportFormat` (enum con casos .csv, .json, .sql)
// que pueda usarse para una futura funcionalidad de exportar resultados.
// Hazlo Sendable, CaseIterable, y con rawValue String.




// MARK: - SESIÓN 3: La Capa de Servicios — Protocolo y SQLite
// ============================================================
//
// OBJETIVOS:
// - Entender el protocolo DatabaseServiceProtocol y su diseño.
// - Comprender cómo funciona la API C de SQLite3 desde Swift.
// - Dominar el patrón de concurrencia: DispatchQueue + Continuations.
//
// ARCHIVOS A REVISAR (en orden):
// 1. Services/DatabaseServiceProtocol.swift
// 2. Services/SQLiteDatabaseService.swift
//
// ────────────────────────────────────────────────────────────
//
// 3.1 — EL PROTOCOLO: DatabaseServiceProtocol
//
// Define CINCO operaciones asíncronas:
//
//   func executeNonQuery(_ sql: String) async throws -> Int
//   func executeQuery(_ sql: String) async throws -> QueryResult
//   func listTables() async throws -> [String]
//   func getTableInfo(_ tableName: String) async throws -> TableInfo
//   func getTableData(_ tableName: String) async throws -> QueryResult
//
// Todas son `async throws`. ¿Por qué?
//
// - `async`: El acceso a disco (SQLite) puede tardar. Si fuera síncrono,
//   bloquearía el hilo principal y la UI se congelaría.
//
// - `throws`: Las operaciones de BD pueden fallar (SQL inválido, tabla
//   inexistente, disco lleno). Con throws, el error se propaga al caller
//   y el ViewModel puede mostrarlo al usuario.
//
// El protocolo también conforma Sendable porque las instancias se pasan
// entre el actor principal (donde vive SwiftUI) y los ViewModels.
//
// ────────────────────────────────────────────────────────────
//
// 3.2 — LA IMPLEMENTACIÓN: SQLiteDatabaseService
//
// Este es el archivo más complejo del proyecto. Analicémoslo por capas:
//
// CAPA 1: DECLARACIÓN Y SEGURIDAD DE HILOS
//
//   final class SQLiteDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
//       private nonisolated(unsafe) var db: OpaquePointer?
//       private let queue = DispatchQueue(label: "com.sqlapp.database", qos: .userInitiated)
//
// - `@unchecked Sendable`: Le dice al compilador "confía en mí, yo manejo
//   la seguridad de hilos manualmente". Normalmente el compilador verifica
//   que todos los campos sean Sendable, pero OpaquePointer (el puntero a
//   la BD de SQLite) no lo es.
//
// - `nonisolated(unsafe) var db`: Este es el puntero a la conexión SQLite.
//   Es `nonisolated` porque se accede desde el DispatchQueue, no desde el
//   MainActor. Es `unsafe` porque el compilador no puede verificar que solo
//   se acceda desde un hilo a la vez. NOSOTROS lo garantizamos con la cola
//   serial.
//
// - `DispatchQueue serial`: TODA operación sobre `db` pasa por esta cola.
//   Al ser serial (no concurrent), solo una operación se ejecuta a la vez.
//   Esto es OBLIGATORIO para SQLite, que no es thread-safe por defecto.
//
// NOTA SOBRE BUENAS PRÁCTICAS:
// El uso de @unchecked Sendable y nonisolated(unsafe) NO es la práctica
// ideal en Swift moderno. Lo ideal sería usar un Actor personalizado.
// Sin embargo, se eligió este enfoque porque:
// 1. SQLite3 es una API de C que usa punteros crudos (OpaquePointer).
// 2. Los actores de Swift no permiten punteros no-Sendable fácilmente.
// 3. El DispatchQueue serial ofrece las mismas garantías de serialización
//    que un actor, solo que el compilador no puede verificarlo.
//
// ────────────────────────────────────────────────────────────
//
// CAPA 2: EL PUENTE ASYNC/AWAIT — performOnQueue
//
// Esta es la función más importante del servicio:
//
//   private nonisolated func performOnQueue<T: Sendable>(
//       _ work: @escaping (OpaquePointer?) throws -> T
//   ) async throws -> T {
//       try await withCheckedThrowingContinuation { continuation in
//           queue.async { [self] in
//               do {
//                   let result = try work(self.db)
//                   continuation.resume(returning: result)
//               } catch {
//                   continuation.resume(throwing: error)
//               }
//           }
//       }
//   }
//
// DESGLOSE PASO A PASO:
//
// 1. El ViewModel llama a `executeQuery("SELECT...")` → es async, así que
//    Swift suspende la ejecución hasta que haya un resultado.
//
// 2. `performOnQueue` crea una CONTINUATION. Una continuation es como un
//    "ticket de espera": la función async se pausa y le da al closure un
//    mecanismo para decir "ya terminé, aquí está el resultado" o "falló".
//
// 3. Dentro de la continuation, se despacha trabajo al DispatchQueue serial.
//    Esto mueve la ejecución a un hilo de background para no bloquear la UI.
//
// 4. El closure `work` recibe `self.db` como parámetro. Esto es intencional:
//    pasar el puntero como parámetro en vez de capturarlo en el closure
//    evita warnings de Sendable (OpaquePointer no conforma Sendable).
//
// 5. Si el trabajo termina bien → continuation.resume(returning: result)
//    Si falla → continuation.resume(throwing: error)
//
// 6. Swift retoma la función async donde se pausó y devuelve el resultado
//    al ViewModel, que está en el MainActor.
//
// REGLA CRÍTICA: Una continuation debe llamar a resume() EXACTAMENTE UNA VEZ.
// Si no la llamas, la función async se queda colgada para siempre.
// Si la llamas dos veces, la app crashea.
//
// ────────────────────────────────────────────────────────────
//
// CAPA 3: OPERACIONES SQLite (API C)
//
// SQLite se usa a través de su API de C importada con `import SQLite3`.
// Los pasos típicos para una consulta son:
//
//   1. sqlite3_prepare_v2(db, sql, -1, &statement, nil)
//      → Compila el SQL en un "statement" ejecutable.
//      → Devuelve SQLITE_OK si el SQL es válido.
//
//   2. sqlite3_step(statement)
//      → Ejecuta un paso. Para SELECT, cada step avanza una fila.
//      → Devuelve SQLITE_ROW si hay más filas, SQLITE_DONE si terminó.
//
//   3. sqlite3_column_text(statement, columnIndex)
//      → Lee el valor de una columna como texto C (UnsafePointer<CChar>).
//
//   4. sqlite3_finalize(statement)
//      → Libera la memoria del statement. SIEMPRE debe llamarse, incluso
//        si hubo error. Es como cerrar un archivo después de leerlo.
//
// Para comandos que no devuelven filas (CREATE, INSERT, etc.),
// se usa `sqlite3_exec()` que es una función de conveniencia que
// combina prepare + step + finalize en una sola llamada.
//
// EJERCICIO SESIÓN 3:
// Lee SQLiteDatabaseService.swift completo. Identifica:
// a) ¿Dónde se abre la conexión a la BD?
// b) ¿Dónde se cierra?
// c) ¿Qué pasa si sqlite3_prepare_v2 falla?
// d) ¿Por qué executeQuery usa prepare/step/finalize y executeNonQuery usa exec?




// MARK: - SESIÓN 4: ViewModels y el Macro @Observable
// ============================================================
//
// OBJETIVOS:
// - Entender el macro @Observable y por qué reemplaza a ObservableObject.
// - Saber cuándo usar @State, @Bindable y let para ViewModels en las vistas.
// - Comprender el flujo de datos unidireccional en MVVM.
//
// ARCHIVOS A REVISAR (en orden):
// 1. ViewModels/QueryEditorViewModel.swift
// 2. ViewModels/TableBrowserViewModel.swift
// 3. ViewModels/SettingsViewModel.swift
// 4. ContentView.swift (repaso de cómo se crean y pasan)
//
// ────────────────────────────────────────────────────────────
//
// 4.1 — @Observable vs ObservableObject
//
// ANTES (iOS 13-16, Combine):
//
//   class MyViewModel: ObservableObject {
//       @Published var name: String = ""      // Requiere wrapper
//       @Published var isLoading: Bool = false // En cada propiedad
//   }
//
//   struct MyView: View {
//       @StateObject var vm = MyViewModel()    // @StateObject para crear
//       // o @ObservedObject si viene de fuera
//   }
//
// AHORA (iOS 17+, Observation framework):
//
//   @Observable
//   class MyViewModel {
//       var name: String = ""      // Sin wrapper, solo var
//       var isLoading: Bool = false // Automáticamente tracked
//   }
//
//   struct MyView: View {
//       @State var vm = MyViewModel()     // @State para crear
//       // o @Bindable si viene de fuera y necesitas bindings
//       // o let si solo necesitas leer
//   }
//
// ¿QUÉ HACE EL MACRO @Observable?
// En tiempo de compilación, transforma cada `var` en una propiedad con
// getter y setter que notifican al framework de Observation. Cuando SwiftUI
// lee una propiedad dentro de `body`, automáticamente se "suscribe" a
// cambios en esa propiedad específica. Cuando la propiedad cambia, SwiftUI
// re-evalúa SOLO las vistas que leen esa propiedad.
//
// VENTAJA CLAVE: Con ObservableObject + @Published, cambiar CUALQUIER
// propiedad @Published re-evaluaba TODAS las vistas que observaban ese
// objeto. Con @Observable, la granularidad es por propiedad.
//
// ────────────────────────────────────────────────────────────
//
// 4.2 — CÓMO SE USAN LOS VIEWMODELS EN LAS VISTAS
//
// Hay TRES formas de recibir un ViewModel en una vista:
//
// 1. @State — "Yo lo creo y soy su dueño"
//
//    @State private var settingsVM = SettingsViewModel()
//
//    Usado en ContentView. El ViewModel se crea UNA vez y sobrevive
//    mientras ContentView exista. Incluso si SwiftUI re-evalúa body,
//    el @State conserva la misma instancia.
//
// 2. @Bindable — "Me lo pasan y necesito crear bindings ($)"
//
//    @Bindable var viewModel: QueryEditorViewModel
//
//    Usado en QueryEditorView. Permite escribir `$viewModel.sqlText`
//    para crear un Binding<String> que la vista puede pasar a un
//    TextField o a nuestro SQLTextEditorView.
//
// 3. let — "Me lo pasan y solo lo leo"
//
//    let settingsViewModel: SettingsViewModel
//
//    Usado en QueryEditorView para el color. No necesita bindings ($),
//    solo lee settingsViewModel.keywordUIColor. Aun así, como es
//    @Observable, si el color cambia en Settings, la vista se actualiza.
//
// ¿POR QUÉ NO @ObservedObject NI @StateObject?
// Esos property wrappers son del framework Combine (ObservableObject).
// Con @Observable no se necesitan. SwiftUI detecta automáticamente
// el acceso a propiedades @Observable sin wrappers especiales.
// @State y @Bindable son los reemplazos modernos.
//
// ────────────────────────────────────────────────────────────
//
// 4.3 — FLUJO DE DATOS EN QueryEditorViewModel
//
// El ViewModel más complejo es QueryEditorViewModel. Su flujo es:
//
//   ENTRADA:
//   - sqlText (lo que escribe el usuario)
//   - executeSQL() (el usuario toca Run)
//   - clearResults() (el usuario toca el botón de dismiss)
//
//   PROCESAMIENTO:
//   - Determina si es SELECT/PRAGMA o DML/DDL
//   - Llama al servicio de BD apropiado (executeQuery o executeNonQuery)
//   - Maneja errores
//
//   SALIDA:
//   - queryResult (tabla de resultados para SELECT)
//   - errorMessage (texto del error si falló)
//   - executionMessage ("5 row(s) returned")
//   - executionStatus (.success/.error para hápticos)
//   - isExecuting (muestra/oculta el ProgressView)
//   - queryHistory (historial de la sesión)
//
// La vista SOLO lee estas propiedades de salida. Nunca accede al servicio
// de BD directamente. Esto es la esencia de MVVM.
//
// EJERCICIO SESIÓN 4:
// Modifica QueryEditorViewModel para que el historial se limite a las
// últimas 50 consultas (si hay más de 50, elimina la más antigua al
// agregar una nueva).


// MARK: - SESIÓN 5: Funciones Asíncronas en Profundidad
// ============================================================
//
// OBJETIVOS:
// - Dominar async/await en el contexto de una app iOS.
// - Entender Task {}, .task modifier, y withCheckedThrowingContinuation.
// - Saber cómo fluyen los datos entre hilos en esta app.
//
// ARCHIVOS A REVISAR (en orden):
// 1. Services/SQLiteDatabaseService.swift (performOnQueue)
// 2. ViewModels/QueryEditorViewModel.swift (executeSQL)
// 3. ViewModels/TableBrowserViewModel.swift (loadTables)
// 4. Views/QueryEditorView.swift (Button + Task)
// 5. Views/TableListView.swift (.task modifier)
//
// ────────────────────────────────────────────────────────────
//
// 5.1 — EL CICLO COMPLETO DE UNA CONSULTA ASYNC
//
// Cuando el usuario toca "Run", sucede esto:
//
// PASO 1: La vista crea un Task
//
//   Button {
//       dismissKeyboard()
//       Task { await viewModel.executeSQL() }
//   }
//
// `Task { }` crea una tarea asíncrona que se ejecuta de forma concurrente
// con la UI. El `await` indica que la función puede suspenderse (pausarse)
// sin bloquear el hilo principal. La UI sigue respondiendo mientras la
// consulta se ejecuta en background.
//
// PASO 2: El ViewModel actualiza estado y llama al servicio
//
//   func executeSQL() async {
//       isExecuting = true        // ← La UI muestra el spinner
//       let result = try await databaseService.executeQuery(trimmed)
//       queryResult = result      // ← La UI muestra la tabla
//       isExecuting = false       // ← La UI oculta el spinner
//   }
//
// Todas las asignaciones a propiedades @Observable (isExecuting, queryResult)
// ocurren en el MainActor porque el ViewModel no es nonisolated. SwiftUI
// detecta los cambios y actualiza la vista automáticamente.
//
// PASO 3: El servicio ejecuta en background
//
//   func executeQuery(_ sql: String) async throws -> QueryResult {
//       try await performOnQueue { db in
//           // Este código corre en el DispatchQueue serial (background)
//           // Usa la API C de SQLite para ejecutar la consulta
//           return QueryResult(columns: cols, rows: rows)
//       }
//   }
//
// PASO 4: El resultado viaja de vuelta
//
//   performOnQueue → continuation.resume(returning: result)
//   → Swift retoma la función async en el punto donde se pausó
//   → El ViewModel recibe el QueryResult
//   → Lo asigna a queryResult (en MainActor)
//   → SwiftUI re-renderiza la tabla de resultados
//
// ────────────────────────────────────────────────────────────
//
// 5.2 — TASK {} vs .task MODIFIER
//
// Son dos formas de lanzar trabajo async desde SwiftUI:
//
// Task { } — Manual, dentro de acciones de botones o callbacks
//
//   Button {
//       Task { await viewModel.executeSQL() }
//   }
//
//   Se usa cuando el usuario INICIA la acción (tap en un botón).
//   La Task se crea y gestiona manualmente.
//
// .task { } — Automático, vinculado al ciclo de vida de la vista
//
//   .task {
//       await viewModel.loadTables()
//   }
//
//   Se ejecuta cuando la vista APARECE en pantalla.
//   Se cancela automáticamente cuando la vista DESAPARECE.
//   Ideal para carga inicial de datos.
//
// En la app:
// - QueryEditorView usa Task {} para el botón "Run" (acción del usuario).
// - TableListView usa .task {} para cargar las tablas al aparecer.
// - TableDetailView usa .task {} para cargar esquema y datos al navegar.
//
// ────────────────────────────────────────────────────────────
//
// 5.3 — withCheckedThrowingContinuation — EL PUENTE
//
// Esta función es el puente entre el mundo de callbacks (DispatchQueue) y
// el mundo de async/await.
//
// ¿POR QUÉ SE NECESITA?
// SQLite no tiene una API async nativa. El DispatchQueue usa callbacks
// (closures). Pero nuestros ViewModels usan async/await. Necesitamos
// convertir de uno a otro.
//
// VARIANTES:
// - withCheckedContinuation:         Para código que NO lanza errores
// - withCheckedThrowingContinuation: Para código que SÍ puede lanzar errores
// - withUnsafeContinuation:          Sin verificaciones (más rápido, peligroso)
//
// "Checked" significa que Swift verifica en runtime que llames a resume()
// exactamente una vez. Si olvidas llamarlo, verás un warning en consola.
// Si lo llamas dos veces, la app crashea. Esto es una red de seguridad
// durante el desarrollo.
//
// ────────────────────────────────────────────────────────────
//
// 5.4 — MANEJO DE ERRORES ASYNC
//
// El patrón do/catch se usa en dos niveles:
//
// NIVEL SERVICIO (dentro de performOnQueue):
//   do {
//       let result = try work(self.db)
//       continuation.resume(returning: result)
//   } catch {
//       continuation.resume(throwing: error)
//   }
//
// NIVEL VIEWMODEL (en executeSQL):
//   do {
//       let result = try await databaseService.executeQuery(sql)
//       queryResult = result
//       executionStatus = .success(feedbackCounter)
//   } catch {
//       errorMessage = error.localizedDescription
//       executionStatus = .error(feedbackCounter)
//   }
//
// Los errores se propagan desde SQLite → servicio → ViewModel → Vista.
// Cada capa decide qué hacer: el servicio los envuelve en DatabaseError,
// el ViewModel los convierte en texto para la UI.
//
// EJERCICIO SESIÓN 5:
// Agrega un método `executeMultiple(_ statements: [String])` al protocolo
// y al servicio que ejecute varias sentencias SQL en secuencia dentro de
// una transacción (BEGIN/COMMIT/ROLLBACK). Piensa:
// - ¿Qué pasa si la tercera sentencia falla?
// - ¿Cómo reportas cuáles tuvieron éxito y cuáles no?


// MARK: - SESIÓN 6: Persistencia de Datos
// ============================================================
//
// OBJETIVOS:
// - Entender cómo se persisten datos actualmente en la app.
// - Conocer las opciones para escalar la persistencia.
// - Saber cuándo usar UserDefaults vs SQLite vs Core Data vs SwiftData.
//
// ARCHIVOS A REVISAR:
// 1. Services/SQLiteDatabaseService.swift (conexión y ubicación del archivo)
// 2. ViewModels/SettingsViewModel.swift (UserDefaults)
// 3. Models/HexColor.swift (conversión para persistencia)
//
// ────────────────────────────────────────────────────────────
//
// 6.1 — PERSISTENCIA ACTUAL: DOS MECANISMOS
//
// MECANISMO 1: SQLite (datos del usuario)
//
// La base de datos se crea en el directorio Documents del sandbox de la app:
//
//   let documentsURL = FileManager.default
//       .urls(for: .documentDirectory, in: .userDomainMask).first!
//   let dbPath = documentsURL.appendingPathComponent("SQLApp.sqlite").path
//   sqlite3_open(dbPath, &db)
//
// Este archivo persiste entre ejecuciones de la app. Las tablas que crea
// el usuario (CREATE TABLE), los datos que inserta (INSERT), todo vive aquí.
//
// MECANISMO 2: UserDefaults (preferencias)
//
// El color de las keywords se guarda como hex string:
//
//   UserDefaults.standard.set(keywordColorHex, forKey: "sqlKeywordColorHex")
//
// UserDefaults está diseñado para preferencias pequeñas: strings, números,
// booleans. NO es para datos grandes o frecuentes.
//
// ────────────────────────────────────────────────────────────
//
// 6.2 — QUÉ NO SE PERSISTE (Y PODRÍA)
//
// 1. HISTORIAL DE CONSULTAS: Actualmente vive en memoria
//    (QueryEditorViewModel.queryHistory). Se pierde al cerrar la app.
//
//    Para persistirlo, podrías:
//    a) Crear una tabla `query_history` en la misma BD SQLite.
//    b) Guardarla como JSON en un archivo con Codable.
//    c) Usar SwiftData con un modelo @Model.
//
// 2. ÚLTIMA CONSULTA: El texto SQL del editor se pierde al cerrar.
//    Podrías guardarlo en UserDefaults (es un string pequeño).
//
// 3. ESTADO DEL TAB SELECCIONADO: Se pierde al cerrar.
//    Podrías usar @AppStorage (wrapper de UserDefaults para SwiftUI).
//
// ────────────────────────────────────────────────────────────
//
// 6.3 — OPCIONES PARA ESCALAR LA PERSISTENCIA
//
// Si la app creciera, estas serían las opciones:
//
// ┌─────────────────┬──────────────────────────────────────────────┐
// │ TECNOLOGÍA      │ CUÁNDO USARLA                                │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ UserDefaults    │ Preferencias simples (color, toggles, IDs).  │
// │                 │ Máximo unos pocos KB. Sin consultas.          │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ SQLite directo  │ Cuando necesitas control total del SQL.       │
// │ (como ahora)    │ Ideal para apps que SON herramientas SQL.     │
// │                 │ Requiere manejo manual de threading.          │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ Core Data       │ Modelos de datos complejos con relaciones.    │
// │                 │ iCloud sync built-in. Migration tools.        │
// │                 │ Curva de aprendizaje empinada.                │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ SwiftData       │ La alternativa moderna a Core Data (iOS 17+). │
// │                 │ Usa macros (@Model). Menos boilerplate.       │
// │                 │ Integración nativa con SwiftUI.               │
// │                 │ RECOMENDADO para nuevas apps.                 │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ Keychain        │ Datos sensibles (contraseñas, tokens).        │
// │                 │ Encriptado por el sistema operativo.          │
// │                 │ Sobrevive desinstalaciones.                   │
// ├─────────────────┼──────────────────────────────────────────────┤
// │ Archivos JSON   │ Exportar/importar datos. Compartir datos.     │
// │ / Codable       │ No apto para consultas frecuentes.            │
// └─────────────────┴──────────────────────────────────────────────┘
//
// PARA ESTA APP ESPECÍFICA:
// SQLite directo es la opción correcta porque la app ES un cliente SQL.
// Usar Core Data o SwiftData para las tablas del usuario no tendría
// sentido: el usuario define sus propios esquemas con CREATE TABLE.
//
// Para las PREFERENCIAS de la app (historial, color, estado de UI),
// la mejor opción de escalamiento sería SwiftData con un modelo
// @Model para QueryHistoryItem y UserDefaults para settings simples.
//
// ────────────────────────────────────────────────────────────
//
// 6.4 — PATRÓN DE PERSISTENCIA EN SettingsViewModel
//
// El patrón actual es "persistencia inmediata":
//
//   private(set) var keywordColorHex: String {
//       didSet {
//           UserDefaults.standard.set(keywordColorHex, forKey: Self.keywordColorKey)
//           keywordUIColor = HexColor.uiColor(from: keywordColorHex)
//       }
//   }
//
// Cada vez que cambia el hex, se guarda inmediatamente en UserDefaults.
// No hay botón "Guardar" ni concepto de "cambios sin guardar" para esta
// propiedad.
//
// El UIColor se cachea como propiedad almacenada para evitar crear una
// instancia nueva en cada acceso. Esto fue necesario para evitar un bug
// de ciclo infinito: UIColor es un tipo por referencia, y cada instancia
// nueva tiene una dirección de memoria diferente, causando que SwiftUI
// detectara "cambios" inexistentes en updateUIView.
//
// EJERCICIO SESIÓN 6:
// Implementa la persistencia del historial de consultas usando la misma BD
// SQLite. Crea una tabla `_query_history` (con underscore para distinguirla
// de las tablas del usuario) y modifica QueryEditorViewModel para cargar
// el historial al iniciar y guardar cada nueva consulta.


// MARK: - SESIÓN 7: UIViewRepresentable y Syntax Highlighting
// ============================================================
//
// OBJETIVOS:
// - Entender por qué se necesita UIViewRepresentable.
// - Dominar el patrón Coordinator para UIKit ↔ SwiftUI.
// - Comprender el ciclo de vida: makeUIView → updateUIView.
// - Identificar y evitar ciclos de actualización infinitos.
//
// ARCHIVOS A REVISAR (en orden):
// 1. Views/SQLTextEditorView.swift
// 2. Views/SQLTextEditorCoordinator.swift
// 3. Services/SQLSyntaxHighlighter.swift
// 4. Models/SQLKeywords.swift
//
// ────────────────────────────────────────────────────────────
//
// 7.1 — ¿POR QUÉ UIViewRepresentable?
//
// SwiftUI tiene TextEditor, pero solo soporta Binding<String> — texto
// plano sin formato. No puede mostrar palabras en diferentes colores o
// pesos tipográficos. Para eso necesitamos NSAttributedString, que solo
// está disponible en UITextView de UIKit.
//
// UIViewRepresentable es el puente: permite usar cualquier UIView de UIKit
// dentro de SwiftUI.
//
// ────────────────────────────────────────────────────────────
//
// 7.2 — ANATOMÍA DE SQLTextEditorView
//
// Tiene cuatro componentes obligatorios:
//
// 1. typealias UIViewType = UITextView
//    → El tipo de vista UIKit que envuelve.
//
// 2. makeUIView(context:) → UITextView
//    → Se llama UNA vez para crear la vista. Aquí se configura el
//      UITextView: fuente, fondo, delegate, teclado, etc.
//
// 3. updateUIView(_:context:)
//    → Se llama CADA VEZ que SwiftUI detecta un cambio en las propiedades
//      de la vista (@Binding, let, var). Aquí se sincronizan los datos
//      de SwiftUI hacia UIKit.
//
// 4. makeCoordinator() → SQLTextEditorCoordinator
//    → Crea el "coordinador": un objeto NSObject que actúa como delegate
//      del UITextView. Sirve de puente para comunicar cambios de UIKit
//      de vuelta a SwiftUI (a través de Bindings).
//
// ────────────────────────────────────────────────────────────
//
// 7.3 — EL FLUJO BIDIRECCIONAL
//
// SwiftUI → UIKit (updateUIView):
// Cuando el usuario toca "Clear" y sqlText se pone en "", SwiftUI llama
// updateUIView. Este detecta que textView.text ≠ text, y re-aplica el
// highlighting con el nuevo texto.
//
// UIKit → SwiftUI (Coordinator/Delegate):
// Cuando el usuario escribe en el teclado, UITextView llama a
// textViewDidChange en el Coordinator. Este actualiza text.wrappedValue
// con el nuevo texto, lo cual notifica a SwiftUI.
//
// ────────────────────────────────────────────────────────────
//
// 7.4 — PREVENCIÓN DE CICLOS INFINITOS
//
// Este es el problema más peligroso con UIViewRepresentable:
//
// CICLO POTENCIAL:
// 1. Usuario escribe "S" → textViewDidChange → text.wrappedValue = "S"
// 2. SwiftUI detecta cambio en text → llama updateUIView
// 3. updateUIView pone attributedText → dispara textViewDidChange
// 4. textViewDidChange actualiza text → SwiftUI llama updateUIView
// 5. → CICLO INFINITO → "AttributeGraph: cycle detected"
//
// SOLUCIONES IMPLEMENTADAS:
//
// a) Guard en updateUIView:
//    if textView.text != text { ... }
//    Solo actualiza si el texto realmente cambió desde fuera.
//
// b) Flag isUpdating en el Coordinator:
//    guard !isUpdating else { return }
//    isUpdating = true
//    defer { isUpdating = false }
//    Previene que textViewDidChange se ejecute cuando el propio
//    coordinator está modificando el textView.
//
// c) NO manejar focus en updateUIView:
//    Originalmente, updateUIView llamaba becomeFirstResponder() y
//    resignFirstResponder() basado en el binding isFocused. Esto
//    disparaba textViewDidBeginEditing/textViewDidEndEditing, que
//    actualizaban isFocused, que llamaba updateUIView... ciclo.
//
//    SOLUCIÓN: El dismiss del teclado se hace con
//    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...)
//    desde la vista SwiftUI, sin pasar por updateUIView.
//
// d) Cacheo del UIColor:
//    settingsViewModel.keywordUIColor era una propiedad computed que
//    creaba un UIColor nuevo cada vez. Como UIColor es un tipo por
//    referencia, cada instancia es "diferente" para SwiftUI, causando
//    updateUIView innecesarios. Se cacheó como propiedad almacenada.
//
// LECCIÓN: Con UIViewRepresentable, CUALQUIER efecto secundario en
// updateUIView que modifique estado observado por SwiftUI puede causar
// un ciclo infinito. La regla es: updateUIView solo debe LEER estado
// de SwiftUI y ESCRIBIR en la UIView, nunca al revés.
//
// EJERCICIO SESIÓN 7:
// Agrega números de línea al editor SQL. Esto requiere:
// a) Un UIView adicional (label o textView no editable) al lado izquierdo.
// b) Sincronizar el scroll vertical entre ambas vistas.
// c) Actualizar los números cuando el texto cambie.


// MARK: - SESIÓN 8: Vistas SwiftUI y Patrones de UI
// ============================================================
//
// OBJETIVOS:
// - Entender los patrones de UI usados en la app.
// - Dominar ContentUnavailableView, Grid, NavigationStack.
// - Aplicar feedback háptico y animaciones.
//
// ARCHIVOS A REVISAR (en orden):
// 1. Views/QueryEditorView.swift
// 2. Views/ResultsTableView.swift
// 3. Views/TableListView.swift
// 4. Views/TableDetailView.swift
// 5. Views/SettingsView.swift
//
// ────────────────────────────────────────────────────────────
//
// 8.1 — COMPOSICIÓN DE VISTAS
//
// QueryEditorView se divide en tres secciones como computed properties:
//
//   var body: some View {
//       VStack(spacing: 0) {
//           sqlInputSection    // Editor de texto
//           controlBar         // Botón Run + status
//           resultsSection     // Tabla de resultados o estado vacío
//       }
//   }
//
// Cada sección es una `private var ... : some View`. Esto es un patrón
// de legibilidad: en lugar de tener un body de 200 líneas, se divide
// en secciones con nombre descriptivo.
//
// ────────────────────────────────────────────────────────────
//
// 8.2 — ESTADOS DE VISTA (Empty, Loading, Error, Content)
//
// La app maneja cuatro estados en varias pantallas:
//
// TableListView:
//   if viewModel.isLoading      → ProgressView
//   else if error                → ContentUnavailableView (error)
//   else if tables.isEmpty       → ContentUnavailableView (vacío)
//   else                         → List de tablas
//
// QueryEditorView (resultsSection):
//   if error                     → ScrollView con Label rojo
//   else if queryResult          → ResultsTableView
//   else if executionMessage     → ContentUnavailableView (checkmark)
//   else                         → ContentUnavailableView ("No Results")
//
// ContentUnavailableView es un componente de Apple (iOS 17+) diseñado
// para estados vacíos y de error. Muestra un icono, un título y una
// descripción de forma consistente con las Human Interface Guidelines.
//
// ────────────────────────────────────────────────────────────
//
// 8.3 — NAVEGACIÓN
//
// La app usa NavigationStack con navegación basada en valores:
//
//   NavigationLink(value: tableName) { ... }
//   .navigationDestination(for: String.self) { tableName in
//       TableDetailView(tableName: tableName, ...)
//   }
//
// ¿Por qué basada en valores y no en destino?
// - Es más declarativa: defines "qué datos" llevan a "qué vista".
// - Permite deep linking futuro (navegar a una tabla por URL).
// - El NavigationStack mantiene el path, permitiendo manipularlo
//   programáticamente.
//
// ────────────────────────────────────────────────────────────
//
// 8.4 — GRID vs LIST vs LazyVStack
//
// ResultsTableView usa Grid (no List) porque necesita:
// - Múltiples columnas alineadas.
// - Scroll horizontal (List solo scrollea vertical).
// - Control preciso del ancho de columnas.
//
// Grid alinea automáticamente las celdas en columnas. GridRow define
// una fila. El ancho de cada columna es el máximo entre todas las
// celdas de esa columna.
//
// Para tablas con muchas filas (100+), LazyVGrid sería más eficiente
// porque solo renderiza las filas visibles. Grid renderiza todas.
//
// ────────────────────────────────────────────────────────────
//
// 8.5 — FEEDBACK HÁPTICO
//
// Se implementa con el modifier .sensoryFeedback:
//
//   .sensoryFeedback(.success, trigger: viewModel.executionStatus) { old, new in
//       if case .success = new { return true }
//       return false
//   }
//
// - El primer parámetro es el TIPO de háptico (.success, .error, .impact).
// - `trigger` es la propiedad que SwiftUI observa.
// - El closure decide si el háptico debe dispararse (return true/false).
//
// Esto es un patrón declarativo: en vez de llamar imperativamente a
// UIFeedbackGenerator, declaras "quiero feedback cuando esta condición
// se cumpla" y SwiftUI se encarga del timing.
//
// EJERCICIO SESIÓN 8:
// Agrega un botón "History" a la toolbar de QueryEditorView que muestre
// un sheet con el historial de consultas. Al tocar una consulta del
// historial, debe cargarla en el editor (usa viewModel.loadHistoryItem).


// MARK: - SESIÓN 9: Testing y Calidad de Código
// ============================================================
//
// OBJETIVOS:
// - Entender cómo la arquitectura actual facilita el testing.
// - Crear un Mock del servicio de base de datos.
// - Escribir unit tests para los ViewModels.
// - Conocer las herramientas de testing en Swift moderno.
//
// ARCHIVOS A REVISAR:
// 1. Services/DatabaseServiceProtocol.swift
// 2. ViewModels/QueryEditorViewModel.swift
// 3. ViewModels/TableBrowserViewModel.swift
//
// ────────────────────────────────────────────────────────────
//
// 9.1 — TESTABILIDAD POR DISEÑO
//
// La razón principal de usar un protocolo (DatabaseServiceProtocol) es
// poder REEMPLAZAR la implementación real en tests:
//
//   final class MockDatabaseService: DatabaseServiceProtocol, @unchecked Sendable {
//       var queryResultToReturn: QueryResult?
//       var errorToThrow: Error?
//
//       nonisolated func executeQuery(_ sql: String) async throws -> QueryResult {
//           if let error = errorToThrow { throw error }
//           return queryResultToReturn ?? QueryResult(columns: [], rows: [])
//       }
//       // ... implementar los demás métodos
//   }
//
// Con este mock, puedes probar el ViewModel SIN una base de datos real:
//
//   @Test func executeSelectUpdatesResult() async {
//       let mock = MockDatabaseService()
//       mock.queryResultToReturn = QueryResult(
//           columns: ["name"], rows: [["Alice"]]
//       )
//       let vm = QueryEditorViewModel(databaseService: mock)
//       vm.sqlText = "SELECT * FROM users"
//
//       await vm.executeSQL()
//
//       #expect(vm.queryResult?.rowCount == 1)
//       #expect(vm.errorMessage == nil)
//   }
//
// ────────────────────────────────────────────────────────────
//
// 9.2 — FRAMEWORK DE TESTING MODERNO
//
// A partir de Xcode 16, Apple ofrece el framework Testing como
// reemplazo de XCTest:
//
//   import Testing
//
//   @Test func miPrueba() async {
//       #expect(resultado == esperado)
//   }
//
// Ventajas sobre XCTest:
// - Sintaxis más concisa (#expect vs XCTAssertEqual)
// - Soporte nativo para async/await
// - Tags y traits para organizar tests
// - Mejor integración con Swift concurrency
//
// ────────────────────────────────────────────────────────────
//
// 9.3 — QUÉ TESTEAR EN ESTA APP
//
// VIEWMODELS (unit tests):
// - executeSQL con SELECT devuelve queryResult y executionMessage correctos
// - executeSQL con INSERT devuelve "N row(s) affected"
// - executeSQL con SQL vacío no ejecuta nada
// - executeSQL con error muestra errorMessage
// - clearResults limpia todos los campos de salida
// - loadHistoryItem pone el SQL correcto en sqlText
// - Historial se actualiza después de cada ejecución
//
// MODELOS (unit tests):
// - HexColor convierte correctamente entre hex y Color
// - SQLKeywords contiene las keywords esperadas
// - QueryResult.isEmpty funciona correctamente
//
// SERVICIO (integration tests):
// - Crear tabla, insertar datos, consultarlos
// - Consultar tabla inexistente genera error apropiado
// - SQL inválido genera error DatabaseError.queryFailed
//
// EJERCICIO SESIÓN 9:
// Crea un target de tests en el proyecto. Implementa MockDatabaseService
// y escribe al menos 5 unit tests para QueryEditorViewModel.


// MARK: - SESIÓN 10: Escalabilidad y Mejoras Futuras
// ============================================================
//
// OBJETIVOS:
// - Identificar limitaciones actuales y cómo superarlas.
// - Diseñar nuevas funcionalidades respetando la arquitectura.
// - Consumo de servicios remotos y APIs externas.
//
// ────────────────────────────────────────────────────────────
//
// 10.1 — LIMITACIONES ACTUALES Y MEJORAS SUGERIDAS
//
// LIMITACIÓN 1: Detección de tipo de consulta por prefijo
//
// Actualmente el ViewModel determina si es SELECT/PRAGMA comparando
// el prefijo del texto. Esto falla con:
//   - "  SELECT ..." (espacios iniciales — ya se maneja con trim)
//   - "WITH cte AS (SELECT ...) SELECT ..." (CTE)
//   - Comentarios antes del SELECT: "-- comment\nSELECT ..."
//
// MEJORA: Implementar un tokenizer SQL básico que ignore comentarios
// y whitespace para encontrar el primer keyword significativo.
//
// LIMITACIÓN 2: Sin paginación de resultados
//
// getTableData tiene LIMIT 200 hardcodeado. Para tablas grandes,
// el usuario no puede ver todos los datos.
//
// MEJORA: Implementar paginación con OFFSET/LIMIT e infinite scroll.
//
// LIMITACIÓN 3: Sin exportación de datos
//
// No se pueden exportar resultados a CSV, JSON o SQL.
//
// MEJORA: Agregar un ExportService con métodos para cada formato,
// usando ShareLink de SwiftUI para compartir el archivo.
//
// ────────────────────────────────────────────────────────────
//
// 10.2 — CONSUMO DE SERVICIOS REMOTOS
//
// Actualmente la app trabaja exclusivamente con datos locales.
// Si quisieras agregar funcionalidad de sincronización o importación
// desde una API, el patrón sería:
//
// PASO 1: Definir un protocolo para el servicio remoto
//
//   protocol RemoteDatabaseServiceProtocol: Sendable {
//       func fetchSchema(from url: URL) async throws -> [TableInfo]
//       func fetchTableData(from url: URL, tableName: String) async throws -> QueryResult
//   }
//
// PASO 2: Implementar con URLSession
//
//   final class RemoteDatabaseService: RemoteDatabaseServiceProtocol {
//       private let session: URLSession
//
//       func fetchSchema(from url: URL) async throws -> [TableInfo] {
//           let (data, response) = try await session.data(from: url)
//
//           guard let httpResponse = response as? HTTPURLResponse,
//                 httpResponse.statusCode == 200 else {
//               throw NetworkError.invalidResponse
//           }
//
//           return try JSONDecoder().decode([TableInfo].self, from: data)
//       }
//   }
//
// PASO 3: URLSession.data(from:) es nativo async/await
//
// A diferencia de SQLite (donde necesitamos withCheckedThrowingContinuation),
// URLSession ya tiene métodos async nativos desde iOS 15:
//
//   let (data, response) = try await URLSession.shared.data(from: url)
//   let (data, response) = try await URLSession.shared.data(for: request)
//   let (url, response)  = try await URLSession.shared.download(from: url)
//
// Estos métodos suspenden la tarea actual sin bloquear ningún hilo.
// No necesitas completion handlers ni delegates.
//
// PASO 4: Decodificación con Codable
//
// Para consumir APIs REST, los modelos necesitan conformar Codable:
//
//   struct TableInfo: Codable, Sendable {
//       let name: String
//       let columns: [ColumnInfo]
//   }
//
// JSONDecoder().decode(T.self, from: data) convierte JSON a Swift structs.
// JSONEncoder().encode(value) convierte de vuelta a JSON.
// Esto permitiría exportar/importar esquemas y datos como JSON.
//
// ────────────────────────────────────────────────────────────
//
// 10.3 — PATRÓN PARA SERVICIOS CON AUTENTICACIÓN
//
// Si la API requiere autenticación (tokens, API keys):
//
//   final class AuthenticatedRemoteService: RemoteDatabaseServiceProtocol {
//       private let token: String
//       private let session: URLSession
//
//       func fetchSchema(from url: URL) async throws -> [TableInfo] {
//           var request = URLRequest(url: url)
//           request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//           let (data, _) = try await session.data(for: request)
//           return try JSONDecoder().decode([TableInfo].self, from: data)
//       }
//   }
//
// El token se almacenaría en Keychain (no UserDefaults — datos sensibles).
//
// ────────────────────────────────────────────────────────────
//
// 10.4 — ARQUITECTURA PARA MÚLTIPLES FUENTES DE DATOS
//
// Si la app necesitara soportar BD local + remota, podrías crear un
// servicio compuesto:
//
//   final class CompositeDatabaseService: DatabaseServiceProtocol {
//       private let local: any DatabaseServiceProtocol
//       private let remote: RemoteDatabaseServiceProtocol
//
//       func executeQuery(_ sql: String) async throws -> QueryResult {
//           try await local.executeQuery(sql) // Siempre local
//       }
//
//       func syncFromRemote(url: URL) async throws {
//           let tables = try await remote.fetchSchema(from: url)
//           for table in tables {
//               // Crear tabla local y copiar datos
//           }
//       }
//   }
//
// El ViewModel seguiría dependiendo de DatabaseServiceProtocol y no
// sabría si los datos vienen de SQLite local o de una API remota.
// Esta es la potencia de la inyección de dependencias.
//
// ────────────────────────────────────────────────────────────
//
// 10.5 — RESUMEN DE BUENAS PRÁCTICAS DEL PROYECTO
//
// ✓ MVVM con separación estricta de responsabilidades
// ✓ Un tipo por archivo para facilitar mantenimiento
// ✓ Protocolos para abstraer dependencias (SOLID - D)
// ✓ @Observable para estado reactivo moderno
// ✓ async/await para operaciones asíncronas
// ✓ Sendable para seguridad entre hilos
// ✓ Serial DispatchQueue para acceso serializado a SQLite
// ✓ Modelos inmutables (structs) para datos del dominio
// ✓ Feedback háptico y visual para acciones del usuario
// ✓ Componentes reutilizables (ResultsTableView en dos pantallas)
//
// ⚠ TRADE-OFFS ACEPTADOS (no ideales pero justificados):
//
// - @unchecked Sendable en el servicio: Porque OpaquePointer (SQLite C API)
//   no conforma Sendable. Un Actor sería más seguro pero incompatible con
//   la captura del puntero.
//
// - nonisolated(unsafe) para db: Porque el puntero se accede desde el
//   DispatchQueue, no desde el MainActor. La seguridad la garantiza la
//   cola serial, no el compilador.
//
// - Detección de SELECT por prefijo: Simplificación válida para un MVP.
//   Un parser SQL completo sería over-engineering para el alcance actual.
//
// - Historial en memoria: Aceptable para la fase actual. Debe persistirse
//   cuando la app escale.
//
// EJERCICIO FINAL SESIÓN 10:
// Diseña (sin implementar) una funcionalidad completa de "Exportar a CSV".
// Documenta:
// a) ¿Qué protocolo/servicio nuevo necesitas?
// b) ¿Qué ViewModel se modifica o crea?
// c) ¿Cómo se presenta al usuario (botón, sheet, share sheet)?
// d) ¿Cómo manejas errores durante la exportación?
// e) Dibuja el diagrama de flujo completo.
