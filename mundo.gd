extends Node2D

# Referencias a los nodos de la escena
@onready var tile_map = $Mapa
@onready var linea_camino = $LineaCamino
@onready var personaje = $Personaje

# Instancia de la clase AStarGrid2D (El algoritmo nativo de Godot 4)
var astar_grid = AStarGrid2D.new()

func _ready():
	# 1. Configurar las propiedades básicas de la grilla
	# region: define el área donde el algoritmo va a trabajar. 
	# Usamos get_used_rect() para que se adapte automáticamente al tamaño del laberinto
	astar_grid.region = tile_map.get_used_rect()
	
	# cell_size: Debe coincidir EXACTAMENTE con el tamaño del tiles (32x32)
	astar_grid.cell_size = Vector2(32, 32)
	
	# geometry: Define cómo se conectan los puntos (4 lados u 8 lados con diagonales)
	# DEFAULT = 4 direcciones (Arriba, Abajo, Izq, Der).
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	# 2. Inicializar la estructura de datos 
	astar_grid.update()
	
	# 3. Sincronizar los obstáculos visuales con el algoritmo lógico
	actualizar_obstaculos()
	
	print("Fase 2 Completada: Grilla A* inicializada correctamente.")

func actualizar_obstaculos():
	# Recorremos todas las celdas dentro de la región definida
	var region_rect = astar_grid.region
	
	for x in range(region_rect.position.x, region_rect.end.x):
		for y in range(region_rect.position.y, region_rect.end.y):
			var celda_coords = Vector2i(x, y)
			
			# Preguntamos al TileMap: "¿Hay algo dibujado en esta coordenada?"
			# get_cell_source_id devuelve -1 si la celda está vacía.
			# NOTA: Si usas TileMap (Godot 4.0-4.2), usa: tile_map.get_cell_source_id(0, celda_coords)
			# Si usas TileMapLayer (Godot 4.3), usa: tile_map.get_cell_source_id(celda_coords)
			
			# Intenta primero con esta línea (TileMapLayer / Godot 4.3):
			var tile_data = tile_map.get_cell_source_id(celda_coords)
			
			# Si te da error, comenta la de arriba y usa esta (TileMap antiguo):
			# var tile_data = tile_map.get_cell_source_id(0, celda_coords)
			
			if tile_data != -1:
				# Si hay un tile visual, marcamos el punto como "SOLIDO" en el algoritmo
				astar_grid.set_point_solid(celda_coords, true)

func _input(event):
	# Detectamos si el usuario hizo clic izquierdo
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		buscar_camino()

func buscar_camino():
	# 1. Limpiamos la línea anterior
	linea_camino.clear_points()
	
	# 2. CONVERSIÓN DE COORDENADAS 
	# El mouse y el personaje están en "Pixeles" (World Position).
	# El algoritmo A* solo entiende de "Celdas" (Grid Coordinates: 0,0 | 0,1 | etc).
	
	# Convertimos la posición del personaje a coord de grilla
	var inicio_grid = tile_map.local_to_map(personaje.position)
	
	# Convertimos la posición del mouse a coord de grilla
	var fin_grid = tile_map.local_to_map(get_global_mouse_position())
	
	# 3. PREGUNTA AL ALGORITMO
	# Esta es la línea mágica. Le pedimos a AStar la lista de celdas por las que pasar.
	# get_id_path devuelve un array de Vector2i con las coordenadas de la grilla [ (0,0), (1,0), (1,1)... ]
	var camino_celdas = astar_grid.get_id_path(inicio_grid, fin_grid)
	
	# 4. DIBUJAR LA RESPUESTA
	# Si el camino está vacío, significa que no se puede llegar (hay una pared bloqueando todo)
	if camino_celdas.is_empty():
		print("No se encontró camino o el destino es una pared.")
		return
		
	# Recorremos cada celda del camino encontrado
	for celda in camino_celdas:
		# Convertimos de vuelta: De Grilla -> A Pixeles (para poder dibujar la línea en pantalla)
		# map_to_local nos da el CENTRO exacto del tile.
		var punto_pixel = tile_map.map_to_local(celda)
		
		# Agregamos el punto a la línea visual
		linea_camino.add_point(punto_pixel)
