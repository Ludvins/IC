;;;;;;; JUGADOR DE 3 en RAYA ;;;;;;;

; Version de 3 en raya clásico: fichas que se pueden poner libremente en cualquier posicion libre (i,j) con 0 < i,j < 4
; y cuando se han puesto las 3 fichas las jugadas consisten en desplazar una ficha propia
; de la posición en que se encuentra (i,j) a una contigua

; Hechos para representar un estado del juego

; (Turno X|O)   representa a quien corresponde el turno (X maquina, O jugador)
; (Posicion ?i ?j " "|X|O) representa que la posicion i,j del tablero esta vacia, o tiene una ficha de Clisp o tiene una ficha del contrincante

; Hechos para representar una jugadas

; (Juega X|O ?origen_i ?origen_j ?destino_i ?destino_j) representa que la jugada consiste en desplazar la ficha de la posicion
;   (?origen_i,?origen_j) a la posición (?destino_i,?destino_j)

; El programa en CLIPS sigue la siguiente estategia:
;  - Si puede ganar lo hace.
;  - Si puede evitar que el contrario gane lo hace.
;  - Si empieza el la partida, entonces la gana incondicionalmente ya que tiene el conocimiento para hacerlo.


; INICIALIZAR ESTADO

; Tablero
; |   | a | b | c |
; | 1 |   |   |   |
; | 2 |   |   |   |
; | 3 |   |   |   |

; Inicializa las relaciones de las posiciones del tablero.
; Conectado i1 j1 f i2 j2 indica que las posiciones (i1,j1) y (i2,j2) están conectadas de la forma que indica 'f', donde:
; h: Horizontal
; v: Vertical
; d1: Diagonal Principal
; d2: Diagonal Secundaria
(deffacts Tablero
  (Conectado 1 a h 1 b)
  (Conectado 1 b h 1 c)
  (Conectado 2 a h 2 b)
  (Conectado 2 b h 2 c)
  (Conectado 3 a h 3 b)
  (Conectado 3 b h 3 c)
  (Conectado 1 a v 2 a)
  (Conectado 2 a v 3 a)
  (Conectado 1 b v 2 b)
  (Conectado 2 b v 3 b)
  (Conectado 1 c v 2 c)
  (Conectado 2 c v 3 c)
  (Conectado 1 a d1 2 b)
  (Conectado 2 b d1 3 c)
  (Conectado 1 c d2 2 b)
  (Conectado 2 b d2 3 a)
  )

; En el estado inicial, ninguna posición tiene ficha y ambos jugadores tienen 3 fichas sin colocar.
(deffacts Estado_inicial
  (Posicion 1 a " ")
  (Posicion 1 b " ")
  (Posicion 1 c " ")
  (Posicion 2 a " ")
  (Posicion 2 b " ")
  (Posicion 2 c " ")
  (Posicion 3 a " ")
  (Posicion 3 b " ")
  (Posicion 3 c " ")
  (Fichas_sin_colocar O 3)
  (Fichas_sin_colocar X 3)
  )

; Definimos  la simetria en la regla 'conectado'
(defrule Conectado_es_simetrica
  (declare (salience 1))
  (Conectado ?i ?j ?forma ?i1 ?j1)
 =>
  (assert (Conectado ?i1 ?j1 ?forma ?i ?j))
)

; Comprueba si (i1,j1) e (i2,j2) están alineados
(defrule Estan_en_linea
  (declare (salience 1))
  (or
  (Conectado ?i1 ?j1 ?forma ?i2 ?j2)
  (and
    (Conectado ?i1 ?j1 ?forma ?i3 ?j3)
    (Conectado ?i3 ?j3 ?forma ?i2 ?j2)
    (or
     (test (neq ?i1 ?i2))
     (test (neq ?j1 ?j2))
     )
   )
  )
 =>
  (assert (En_linea ?forma ?i1 ?j1 ?i2 ?j2))
)

; Comprueba si un jugador tiene 2 fichas en la misma linea,
; No existe simetría en la regla.
;
; Utilizamos la macro 'logical' para marcar que si alguna de las fichas involucradas se mueve,
; ya no estarían en linea.
(defrule 2_fichas_en_linea
  (declare (salience 2))
  (logical
   (Posicion ?i2 ?j2 ?p)
   (Posicion ?i1 ?j1 ?p)
   )
  (En_linea ?f ?i1 ?j1 ?i2 ?j2)
  (not (2_en_linea ?f ?i2 ?j2 ?i1 ?j1 ?p))
  (test (neq ?p " "))
 =>
  ; (printout t "[DEBUG]: 2 fichas en linea de "?p ", son " ?i1 ?j1 " y " ?i2 ?j2 crlf)
  (assert (2_en_linea ?f ?i1 ?j1 ?i2 ?j2 ?p))
)

; Comprueba si alguno de los dos jugadores puede ganar poniendo una ficha.
; Para ello comprueba si tiene 2 fichas alineadas y la tercera posición está vacia.
;
; En caso de dejar de estar alineadas o que la tercerá posición deje de estar vacia, borramos le hecho.
(defrule Puede_ganar_poniendo_ficha
  (declare (salience 1))
  (logical
   (2_en_linea ?f ?i1 ?j1 ?i2 ?j2 ?p)
   (Posicion ?i3 ?j3 " ")
   (not (Todas_fichas_en_tablero ?p))
   )
  (En_linea ?f ?i1 ?j1 ?i3 ?j3)
 =>
  ; (printout t "[DEBUG]: Puede ganar el jugador " ?p " poniendo ficha en " ?i3"-"?j3 crlf)
  (assert (Puede_ganar_poniendo ?i3 ?j3 ?p))
)

; Comprueba si un jugador puede ganar la partida moviendo una ficha de la posición
; (i4,j4) a la (i3,j3).
;
; Para ello comprueba que (i1,j1)-(i2,j2) son fichas alineadas.
;
; Utilizamos 'logical' al igual que en el caso anterior.
(defrule Puede_ganar_moviendo_ficha
  (declare (salience 1))
  (logical
   (2_en_linea ?f ?i1 ?j1 ?i2 ?j2 ?p)
   (Posicion ?i3 ?j3 " ")
   )
  (Todas_fichas_en_tablero ?p)
  (En_linea ?f ?i1 ?j1 ?i3 ?j3)

  (Conectado ?i3 ?j3 ?h ?i4 ?j4)
  (Posicion ?i4 ?j4 ?p)
  (not (En_linea ?f ?i4 ?j4 ?i1 ?j1))
  (not (En_linea ?f ?i4 ?j4 ?i2 ?j2))
 =>
  ; (printout t "[DEBUG]: Puede ganar el jugador " ?p " moviendo " ?i4"-"?j4 " a " ?i3"-"?j3 crlf)
  (assert (Puede_ganar_moviendo ?i4 ?j4 ?i3 ?j3 ?p))
)


; Elección de comienzo de turno
(defrule Elige_quien_comienza =>
  (printout t "Quien quieres que empieze: (escribe X para la maquina u O para empezar tu) ")
  (assert (Turno (read)))
)

;;;;;;;;;;;;;;;;;;;;;;; RECOGER JUGADA DEL CONTRARIO ;;;;;;;;;;;;;;;;;;;;;;;
(defrule muestra_posicion
  (declare (salience 1))
  (muestra_posicion)
  (Posicion 1 a ?p11)
  (Posicion 1 b ?p12)
  (Posicion 1 c ?p13)
  (Posicion 2 a ?p21)
  (Posicion 2 b ?p22)
  (Posicion 2 c ?p23)
  (Posicion 3 a ?p31)
  (Posicion 3 b ?p32)
  (Posicion 3 c ?p33)
 =>
  (printout t crlf)
  (printout t "   a      b      c" crlf)
  (printout t "   -      -      -" crlf)
  (printout t "1 |" ?p11 "| -- |" ?p12 "| -- |" ?p13 "|" crlf)
  (printout t "   -      -      -" crlf)
  (printout t "   |  \\   |   /  |" crlf)
  (printout t "   -      -      -" crlf)
  (printout t "2 |" ?p21 "| -- |" ?p22 "| -- |" ?p23 "|" crlf)
  (printout t "   -      -      -" crlf)
  (printout t "   |   /  |  \\   |" crlf)
  (printout t "   -      -      -" crlf)
  (printout t "3 |" ?p31 "| -- |" ?p32 "| -- |" ?p33 "|"crlf)
  (printout t "   -      -      -" crlf)
)

(defrule muestra_posicion_turno_jugador
  (declare (salience 10))
  (Turno O)
 =>
  (assert (muestra_posicion))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; JUEGA HUMANO ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule jugada_contrario_fichas_sin_colocar
  ?f <- (Turno O)
  (Fichas_sin_colocar O ?n)
 =>
  (printout t "En que posicion colocas la siguiente ficha" crlf)
  (printout t "Escribe la fila (1,2 o 3): ")
  (bind ?fila (read))
  (printout t "Escribe la columna (a,b o c): ")
  (bind ?columna (read))
  (assert (Juega O 0 0 ?fila ?columna))
  (retract ?f)
)

(defrule juega_contrario_fichas_sin_colocar_check
  (declare (salience 2))
  ?f <- (Juega O 0 0 ?i ?j)
  (not (Posicion ?i ?j " "))
 =>
  (printout t "No puedes jugar en " ?i ?j " porque no esta vacio" crlf)
  (retract ?f)
  (assert (Turno O))
)

(defrule juega_contrario_fichas_sin_colocar_actualiza_estado
  ?f <- (Juega O 0 0 ?i ?j)
  ?g <- (Posicion ?i ?j " ")
 =>
  (retract ?f ?g)
  (assert (Turno X) (Posicion ?i ?j O) (reducir_fichas_sin_colocar O))
)


(defrule juega_contrario
  ?f <- (Turno O)
  (Todas_fichas_en_tablero O)
 =>
  (printout t "¿En que posicion esta la ficha que quieres mover?" crlf)
  (printout t "¿Escribe la fila (1,2,o 3): ")
  (bind ?origen_i (read))
  (printout t "¿Escribe la columna (a,b o c): ")
  (bind ?origen_j (read))
  (printout t "¿A que posicion la quieres mover?" crlf)
  (printout t "Escribe la fila (1,2,o 3): ")
  (bind ?destino_i (read))
  (printout t "Escribe la columna (a,b o c): ")
  (bind ?destino_j (read))
  (assert (Juega O ?origen_i ?origen_j ?destino_i ?destino_j))
  (printout t "Juegas mover la ficha de "  ?origen_i ?origen_j " a " ?destino_i ?destino_j crlf)
; Actualizar 2_en_linea
  (retract ?f)
)

(defrule juega_contrario_check_mueve_ficha_propia
  (declare (salience 2))
  ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
  (Posicion ?origen_i ?origen_j ?X)
  (test (neq O ?X))
 =>
  (printout t "No es jugada valida porque en " ?origen_i ?origen_j " no hay una ficha tuya" crlf)
  (retract ?f)
  (assert (Turno O))
)

(defrule juega_contrario_check_mueve_a_posicion_libre
  (declare (salience 2))
  ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
  (Posicion ?destino_i ?destino_j ?X)
  (test (neq " " ?X))
 =>
  (printout t "No es jugada valida porque " ?destino_i ?destino_j " no esta libre" crlf)
  (retract ?f)
  (assert (Turno O))
)

(defrule juega_contrario_check_conectado
  (declare (salience 2))
  (Todas_fichas_en_tablero O)
  ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
  (not (Conectado ?origen_i ?origen_j ? ?destino_i ?destino_j))
 =>
  (printout t "No es jugada valida porque "  ?origen_i ?origen_j " no esta conectado con " ?destino_i ?destino_j crlf)
  (retract ?f)
  (assert (Turno O))
)

(defrule juega_contrario_actualiza_estado
  ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
  ?h <- (Posicion ?origen_i ?origen_j O)
  ?g <- (Posicion ?destino_i ?destino_j " ")
 =>
  (retract ?f ?g ?h)
  (assert (Turno X) (Posicion ?destino_i ?destino_j O) (Posicion ?origen_i ?origen_j " ") )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;; CONTROL DE FICHAS ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defrule reducir_fichas_sin_colocar
  (declare (salience 2))
  ?f <- (reducir_fichas_sin_colocar ?jugador)
  ?g <- (Fichas_sin_colocar ?jugador ?n)
 =>
  (retract ?f ?g)
  (assert (Fichas_sin_colocar ?jugador (- ?n 1)))
)

(defrule todas_las_fichas_en_tablero
  (declare (salience 2))
  ?f <- (Fichas_sin_colocar ?jugador 0)
 =>
  (retract ?f)
  (assert (Todas_fichas_en_tablero ?jugador))
  (printout t "Todas las fichas en el tablero para el jugador " ?jugador)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;; JUEGA CLISP ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Actualiza las posiciones tras mover una pieza de 'origen' a 'destino'
(defrule juega_clisp_actualiza_estado
  ?f <- (Juega X ?origen_i ?origen_j ?destino_i ?destino_j)
  ?h <- (Posicion ?origen_i ?origen_j X)
  ?g <- (Posicion ?destino_i ?destino_j " ")
 =>
  (retract ?f ?g ?h)
  (assert (Turno O) (Posicion ?destino_i ?destino_j X) (Posicion ?origen_i ?origen_j " ") )
)

; Juego sin criterio poniendo fichas
(defrule clisp_juega_sin_criterio_fichas_sin_colocar
  (declare (salience -9999))
  ?f<- (Turno X)
  (Fichas_sin_colocar X ?n)
  ?g<- (Posicion ?i ?j " ")
 =>
  (printout t "Juego poner ficha en " ?i ?j crlf)
  (retract ?f ?g)
  (assert (Posicion ?i ?j X) (Turno O) (reducir_fichas_sin_colocar X))
)

; Juego sin criterio moviendo ficha
(defrule clisp_juega_sin_criterio
  (declare (salience -9999))
  ?f<- (Turno X)
  (Todas_fichas_en_tablero X)
  (Posicion ?origen_i ?origen_j X)
  (Posicion ?destino_i ?destino_j " ")
  (Conectado ?origen_i ?origen_j ? ?destino_i ?destino_j)
 =>
  (assert (Juega X ?origen_i ?origen_j ?destino_i ?destino_j))
  (printout t "Juego mover la ficha de "  ?origen_i ?origen_j " a " ?destino_i ?destino_j crlf)
  (retract ?f)
)

; Clisp evita que el contrario gane poniendo una ficha.
(defrule evita_contrario_gane_fichas_poniendo
  (declare (salience -5))
  ?f <- (Turno X)
  (Fichas_sin_colocar X ?n)
  (or
   (Puede_ganar_poniendo ?i ?j O)
   (Puede_ganar_moviendo ? ? ?i ?j O)
   )
  ?g <- (Posicion ?i ?j " ")
 =>
  (printout t "[Con criterio]: Evito que el contrario gane poniendo ficha en " ?i"-"?j crlf)
  (retract ?f ?g)
  (assert (Posicion ?i ?j X) (Turno O) (reducir_fichas_sin_colocar X))
)

; Clisp evita que el contrario gane moviendo ficha de (i1,j1) a (i,j)
(defrule evita_contrario_gane_moviendo
  (declare (salience -5))
  ?f <- (Turno X)
  (not (Fichas_sin_colocar X ?n))
  (or
   (Puede_ganar_poniendo ?i ?j O)
   (Puede_ganar_moviendo ? ? ?i ?j O)
   )
  ?g2 <- (Posicion ?i1 ?j1 X)
  ?g <- (Posicion ?i ?j " ")
  (Conectado ?i1 ?j1 ? ?i ?j)
 =>
  (printout t "[Con criterio]: Evito que el contrario gane moviendo ficha a " ?i"-"?j crlf)
  (retract ?f ?g ?g2)
  (assert (Posicion ?i ?j X) (Turno O) (Posicion ?i1 ?j1 " "))
)

; Clisp gana la partida poniendo una ficha
(defrule gana_poniendo_ficha
  (declare (salience -4))
  ?f <- (Turno X)
  (Fichas_sin_colocar X ?n)
  (Puede_ganar_poniendo ?i ?j X)
  ?g <- (Posicion ?i ?j " ")
 =>
  (printout t "[Con criterio]: Juego poner ficha en " ?i"-"?j crlf)
  (retract ?f ?g)
  (assert (Posicion ?i ?j X) (Turno O) (reducir_fichas_sin_colocar X))
)

; Clisp gana la partida moviendo una ficha
(defrule gana_moviendo_ficha
  (declare (salience -4))
  ?f <- (Turno X)
  (not (Fichas_sin_colocar X ?n))
  (Puede_ganar_moviendo ?i1 ?j1 ?i2 ?j2 X)
  ?g2 <- (Posicion ?i1 ?j1 X)
  ?g <- (Posicion ?i2 ?j2 " ")
 =>
  (printout t "[Con criterio]: Juego poner ficha en " ?i2"-"?j2 crlf)
  (retract ?f ?g ?g2)
  (assert (Posicion ?i2 ?j2 X) (Posicion ?i1 ?j1 " ") (Turno O))
)

;;;;;;;; CONJUNTO DE REGLAS PARA GANAR AL EMPEZAR ;;;;;;;;;

; Si CLISP empieza, coge el centro del tablero
(defrule empiezo_yo
  (declare (salience -10))
  (not (Posicion ? ? O))
  ?f <- (Turno X)
  ?f2 <- (Posicion 2 b " ")
 =>
  (retract ?f ?f2)
  (printout t "[Ganar siempre 1]: Juego poner ficha en 2-b" crlf)
  (assert (Posicion 2 b X) (Turno O) (reducir_fichas_sin_colocar X) (Ganar_siempre_turno_2))
)

; Si el rival pone en un lado (no esquina), respondemos de la siguiente forma
;
; |   | a | b | c |
; | 1 |   |   |   |
; | 2 |   | X | O |
; | 3 | X |   |   |
;
; Para ello buscamos una posición que cumpla
;  - No estar alineada con la ficha del rival.
;  - Estar en diagonal con la ficha central.
;
; Con esto obligamos a el rival a poner en la posición alineada, llegando a la siguiente situacion
; |   | a | b | c |
; | 1 |   |   | O |
; | 2 |   | X | O |
; | 3 | X |   | X |
;
; Donde, en caso de poner O en (1,a), CLISP utilizará las reglas de mover para ganar, pero, en caso de poner O en (3,b), necesitaremos mover la pieza (3,a)->(1,a). Para ello utilizamos 'tercer_turno_1'.
;
(defrule segundo_turno_1
  (declare (salience -10))
  ?f <- (Turno X)
  ?f1 <- (Ganar_siempre_turno_2)
  (Posicion ?i1 ?j1 O)
  (or
  (Conectado 2 b h ?i1 ?j1)
  (Conectado 2 b v ?i1 ?j1)
   )
  ?f2 <- (Posicion ?i2 ?j2 " ")
  (or
  (Conectado 2 b d1 ?i2 ?j2)
  (Conectado 2 b d2 ?i2 ?j2)
   )
  (not (En_linea ? ?i1 ?j1 ?i2 ?j2))
 =>
  (retract ?f ?f1 ?f2)
  (printout t "[Ganar siempre 2]: Juego poner ficha en "?i2"-"?j2 crlf)
  (assert (Posicion ?i2 ?j2 X) (Turno O) (reducir_fichas_sin_colocar X) (Ganar_siempre_turno_3_a))
)

; En esta situación solo buscamos cual es la posición a la que queremos mover la ficha, en este caso
; |   | a | b | c |
; | 1 |   |   | O |
; | 2 |   | X | O |
; | 3 | X | O | X |
;
; Buscamos mover la única ficha que podemos y no es la central, a la única posición posible.
;
; Tras esto, CLIPS utilizará el "ganar_moviendo" para terminar la partida.
(defrule tercer_turno_1
  (declare (salience -10))
  ?f <- (Turno X)
  ?f1 <- (Ganar_siempre_turno_3_a)
  ?f2 <- (Posicion ?i1 ?j1 " ")
  ?f3 <- (Posicion ?i2 ?j2 X)
  (Conectado ?i1 ?j1 ? ?i2 ?j2)
  (test (neq ?i2 2))
 =>
  (retract ?f ?f1 ?f2 ?f3)
  (printout t "[Ganar siempre 3]: Juego mover ficha en "?i1"-"?j1 crlf)
  (assert (Posicion ?i1 ?j1 X) (Posicion ?i2 ?j2 " ") (Turno O))
)


; Si el rival hubiera colocado una ficha en una esquina tal que
;
; |   | a | b | c |
; | 1 |   |   |   |
; | 2 |   | X |   |
; | 3 |   |   | O |
;
; Nosotros buscamos responder de la siguiente forma
;
; |   | a | b | c |
; | 1 |   |   |   |
; | 2 | X | X |   |
; | 3 |   |   | O |
;
; Para ello buscamos una posición conectada de forma vertical u horizontal con el centro
; y que no se encuentre alineada con la ficha del rival
;
;El juego transcurriría tal que asi
; |   | a | b | c |
; | 1 |   |   | X |
; | 2 | X | X | O |
; | 3 | O |   | O |
;
; Luego en 'tercer_turno_2' moveriamos (2,a)->(1,a) ganando la partida en el siguiente turno.
(defrule segundo_turno_2
  (declare (salience -10))
  ?f <- (Turno X)
  ?f1 <- (Ganar_siempre_turno_2)
  (Posicion ?i1 ?j1 O)
  (or
  (Conectado 2 b d1 ?i1 ?j1)
  (Conectado 2 b d2 ?i1 ?j1)
   )
  ?f2 <- (Posicion ?i2 ?j2 " ")
  (or
  (Conectado 2 b h ?i2 ?j2)
  (Conectado 2 b v ?i2 ?j2)
   )
  (not (En_linea ? ?i1 ?j1 ?i2 ?j2))
 =>
  (retract ?f ?f1 ?f2)
  (printout t "[Ganar siempre 2]: Juego poner ficha en "?i2"-"?j2 crlf)
  (assert (Posicion ?i2 ?j2 X) (Turno O) (reducir_fichas_sin_colocar X) (Ganar_siempre_turno_3_b))
)

; Dada la situación anterior, buscamos nuestra ficha que esta conectada a la central de forma horizontal o vertical y la movemos a la única posición posible.

; |   | a | b | c |
; | 1 | X |   | X |
; | 2 |   | X | O |
; | 3 | O |   | O |
(defrule tercer_turno_2
  (declare (salience -10))
  ?f <- (Turno X)
  ?f1 <- (Ganar_siempre_turno_3_b)
  ?f2 <- (Posicion ?i1 ?j1 " ")
  ?f3 <- (Posicion ?i2 ?j2 X)
  (Conectado ?i1 ?j1 ? ?i2 ?j2)
  (or
  (Conectado 2 b h ?i2 ?j2)
  (Conectado 2 b v ?i2 ?j2)
   )
 =>
  (retract ?f ?f1 ?f2 ?f3)
  (printout t "[Ganar siempre 3]: Juego mover ficha en "?i1"-"?j1 crlf)
  (assert (Posicion ?i1 ?j1 X) (Posicion ?i2 ?j2 " ") (Turno O))
)


(defrule tres_en_raya
  (declare (salience 9999))
  ?f <- (Turno ?X)
  (Posicion ?i1 ?j1 ?jugador)
  (Posicion ?i2 ?j2 ?jugador)
  (Posicion ?i3 ?j3 ?jugador)
  (Conectado ?i1 ?j1 ?forma ?i2 ?j2)
  (Conectado ?i2 ?j2 ?forma ?i3 ?j3)
  (test (neq ?jugador " "))
  (test (or (neq ?i1 ?i3) (neq ?j1 ?j3)))
 =>
  (printout t ?jugador " ha ganado pues tiene tres en raya " ?i1 ?j1 " " ?i2 ?j2 " " ?i3 ?j3 crlf)
  (retract ?f)
  (assert (muestra_posicion))
)


