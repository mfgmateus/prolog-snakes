% Importando bibliotecas do plOpenGL para utilização
% de binds do teclado
:- use_foreign_library(foreign(plOpenGL)).
:- use_module(library(plGLUT_defs)).
:- use_module(library(plGLUT)).
% Importando biblioteca by_unix para dar um clear na tela
:- use_module(library(by_unix)).

% Definindo predicados que podem ser modificados
% em runtime
:- dynamic food/1, snake/1, direction/2.

% Cria função que chama o comando clear do sistema
% utilizando a biblioteca by_unix
clear :- @ clear.

% limit/2 - limit(LimitX,LimitY)
% Define os limites das paredes
limit(11,19).

% Define a Snake inicial
startSnake([[2,4,right],[2,5,right],[2,6,right],[2,7,right]]).
snake([[2,4,right],[2,5,right],[2,6,right],[2,7,right]]).

% Mensagem de Game Over
gameOver(['*',' ',' ',' ',' ','GAME OVER',' ',' ',' ',' ',' ','*']).

% Mensagem de Restart
restart(['*','   R to Restart   ','*']).

% Define os códigos da teclas para cada direção
direction(97,left).
direction(100,right).
direction(115,down).
direction(119,up).
direction([[_|[_|[Direction|_]]]|_],Direction).
direction(head,right).

key(27,esc).
key(114,restart).

% Define os decrescimentos de acordo com a direção
decrease(left,0,-1).
decrease(right,0,1).
decrease(up,-1,0).
decrease(down,1,0).

% Inicia a lista de comidas como vazia
food([]).

% Define os limites das paredes
wall(0,_).
wall(_,0).

%wall(X,Y) :- 
%    X = 6,
%    Y > 3,
%    Y < 15.

%wall(X,Y) :- 
%    Y = 9,
%    X > 2,
%    X < 10.

wall(X,_) :- limit(X,_).
wall(_,Y) :- limit(_,Y).

% Define mudanças de direções permitidas

allowed(left,down) :- !.
allowed(left,up) :- !.
allowed(right,down) :- !.
allowed(right,up) :- !.
allowed(X,X) :- !,fail.
allowed(right,left) :- !,fail.
allowed(up,down) :- !,fail.
allowed(X,Z) :- allowed(Z,X).

% Define as direções opostas de cada direção
oposite(left,right).
oposite(right,left).
oposite(up,down).
oposite(down,up).

% head/2 - head(List, Head)
% Retorna o head de alguma lista
head([Head|_],Head).

% tail/2 - tail(List,Tail)
% Retorna o tail de alguma lista
tail([_|[]],[]) :- !.
tail([_|Tail],Tail).

% last/2 - last(List,Elem)
% Retorna o ultimo elemento de uma lista

last([Head|[]],Head).
last([_|Tail],Head) :-
    last(Tail,Head).

% foodMember/3 - foodMember(Food, XPoint, YPoint) 
% Verifica se um elemento pertence a lista de comidas
foodMember([[X|[Y|_]]|_],X,Y).
foodMember([_|Tail],X,Y) :-
    foodMember(Tail,X,Y).
    
% snakeMember/3 - snakeMember(Snake,XPoint,YPoint)
% Verifica se os pontos X,Y passados não pertencem a uma Snake
snakeMember([],_,_) :- !, fail.
snakeMember([[X|[Y|_]]|_],X,Y) :- !.
snakeMember([_|Tail],X,Y) :- 
    snakeMember(Tail,X,Y).

% random/4 - random(InitialRange,HorizontalRange,VerticalRange, X, Y) 
% Gera pseudo-randomicos X,Y dados os limites 
% iniciais, horizontais e verticais
random(Start,EndH,EndV,X,Y) :-
    random(Start,EndH,X), 
    random(Start,EndV,Y).

% randomFood/3 - randomFood(Snake,X,Y)
% Gera pseudo-randomicos X,Y dados os limites iniciais, horizontais 
% e verticais que não pertencem ao corpo de uma Snake
randomFood(Snake,X,Y) :- 
    limit(LimitX,LimitY),
    LimitX2 is LimitX-1,
    LimitY2 is LimitY-1,
   	random(1,LimitX2,LimitY2,X,Y),
    not(snakeMember(Snake,X,Y)), 
    not(wall(X,Y)).

randomFood(Snake,X,Y) :- 
    randomFood(Snake,X,Y).

% snakeHead/3 - snakeHead(Snake,X,Y)
% Retorna os pontos X,Y que são cabeça da Snake
snakeHead(Snake,X,Y):-
    last(Snake,[X|[Y|_]]).

% snakeHead/2 - snakeHead(Snake,Direction)
% Retorna a direção da cabeça da Snake
snakeHead(Snake,Direction):-
    last(Snake,[_|[_|[Direction|_]]]).

% colideHead/2 - colideHead(FoodList,SnakeList)
% Verificar se a primeira comida colidiu com a cabeça da Snake
colideHead([[X|[Y|_]]|_],Snake) :-
    snakeHead(Snake,X,Y).

% colideTail/2 - colideTail(FoodList,SnakeList)
% Verificar se a ultima comida colidiu com o 
% ultimo elemento da cauda da Snake
colideTail(Food,[[X|[Y|_]]|_]) :-
	last(Food,[X,Y]).

% colideWall/1 - colideWall(Snake)
% Verificar se a cabeça da Snake colidiu com alguma parede
colideWall(Snake) :-
    snakeHead(Snake,X,Y),
    wall(X,Y), !.

% colideSnake/2 - colideSnake(Snake,Snake)
% Verifica se a cabeça da Snake colidiu com algum elemento do corpo
colideSnake(_,Tail) :- 
    tail(Tail,[]),
    !, fail.

colideSnake(Snake,[[X|[Y|_]]|_]) :-
    snakeHead(Snake,X,Y), !. 

colideSnake(Snake,[_|Tail]) :-
    colideSnake(Snake,Tail).

% newNode/2 - newNode(BeforeNode,Node)
% Retorna um nó baseado no último elemento da cauda 
newNode([X|[Y|[Direction|_]]],NewNode) :-
    oposite(Direction,OpositeDirection),
    decrease(OpositeDirection,DecreaseX,DecreaseY),
    NodeX is X + DecreaseX,
    NodeY is Y + DecreaseY,
    NewNode = [NodeX,NodeY,Direction].

% addSnakeNode/2 - addSnakeNode(Snake,NewSnake)
% Adiciona nó a Snake baseado no último elemento da cauda 
addSnakeNode(Snake,[Node|Snake]) :-
    head(Snake,OldNode),
    newNode(OldNode,Node).

% addFoodNode/3 - addFoodNode(SnakeList,FoodList,NewFoodList)
% Adiciona uma comida randômica a lista de comidas
addFoodNode(Snake,Food,[Node|Food]) :-
    randomFood(Snake,X,Y),
    Node = [X,Y].

% removeFoodNode/2 - removeFoodNode(Food,NewFood)
% Remove o último elemento da lista de comidas
removeFoodNode([_],[]).
removeFoodNode([X|Xs], [X|WithoutLast]) :- 
        removeFoodNode(Xs, WithoutLast).

% getSymbol/5 - getSymbol(Snake,Food,X,Y,Symbol)
% Pega símbolo de acordo com o ponto X,Y
% Retorna símbolo * caso X,Y pertença a parede
getSymbol(_,_,X,Y,Symbol) :-
    wall(X,Y),
    Symbol = '*', !.

% Retorna símbolo o caso X,Y pertença a lista de comidas
% e da Snake
getSymbol(Snake,Food,X,Y,Symbol) :-
    foodMember(Food,X,Y),
    snakeMember(Snake,X,Y),
    Symbol = 'o', !.

% Retorna símbolo + caso X,Y pertença a lista de comidas
getSymbol(_,Food,X,Y,Symbol) :-
    foodMember(Food,X,Y),
    Symbol = '+', !.

% Retorna símbolo 'º' caso X,Y pertença a cabeça snake
getSymbol(Snake,_,X,Y,Symbol) :-
    snakeHead(Snake,X,Y),
    Symbol = 'º', !.

% Retorna símbolo '°' caso X,Y pertença a snake
getSymbol(Snake,_,X,Y,Symbol) :-
    snakeMember(Snake,X,Y),
    Symbol = '°', !.

% Retorna ' ' caso nenhum simbolo seja encontrado
getSymbol(_,_,_,_,' ').

% print/1 - print(Lista)
% Printa uma Lista de Listas
print([]) :- !.
print([X|XS]) :- printElem(X),print(XS).

% printElem/1 - printElem(Lista)
% Printa uma Lista
printElem([]) :- nl, !.
printElem([X|XS]) :- write(X),printElem(XS).

% createLine/6 - createLine(Snake,Food,StartList,I,J,ResultList)
% Cria uma lista da linha baseada nos pontos da Snake e das Comidas
createLine(_,_,StartList,_,-1,StartList) :- !.
createLine([],[],_,5,_,GameOver) :-
    gameOver(GameOver), !.
createLine([],[],_,6,_,Restart) :-
    restart(Restart), !.
createLine(Snake,Food,StartList,I,J,List) :-
    getSymbol(Snake,Food,I,J,Symbol),
    appendList(StartList,Symbol,NewList),
    Jx is J-1,
    createLine(Snake,Food,NewList,I,Jx,List), !.

% createMatrix/5 - createMatrix(Snake,Food,StartList,I,ResultList)
% Cria uma Lista de Listas a.k.a Matriz
createMatrix(_,_,StartList,-1,StartList) :- !.
createMatrix(Snake,Food,StartList,I,List) :-
    limit(_,LimitY),
    createLine(Snake,Food,[],I,LimitY,Col),
    Ix is I-1,
    appendList(StartList,Col,NewList),
    createMatrix(Snake,Food,NewList,Ix,List), !.

% appendList/3 - appendList(List,Elem,NewList)
% Adiciona um elemento ao inicio de uma lista
appendList(StartList,Elem,List) :-
    List = [Elem|StartList].

% changeAllSnake/2 - changeAllSnake(Snake,NewSnake)
% Movimenta a snake de acordo com os decrescimentos
changeAllSnake([],[]).
changeAllSnake([HeadSnake|TailSnake], [NewSnakeHead|NewTailHead]) :-
    (
        direction(TailSnake,Direction); 
        direction(head,Direction)
    ),
    changeSnake(HeadSnake,Direction,NewSnakeHead),
    changeAllSnake(TailSnake,NewTailHead), !.

% changeSnake/3 - changeSnake(Node,Direction,NewNode)
% Modifica um elemento de uma Snake
% Altera a sua direção e os pontos X,Y
changeSnake([PontoX|[PontoY|[OldDirection|[]]]],Direction,NewNode) :-
    decrease(OldDirection,DecreaseX,DecreaseY),
    NPontoX is PontoX + DecreaseX,
    NPontoY is PontoY + DecreaseY,
    NewNode = [NPontoX,NPontoY,Direction].

% runFood/3 - runFood(Snake,Food,NewFood)
% Verifica se a comida colidiu e adiciona nova comida
runFood(Snake,Food,NewFood) :-
        colideHead(Food,Snake), 
        addFoodNode(Snake,Food,NewFood), !.
runFood(_,Food,Food). 

% runSnake/4 - runFood(Snake,Food,NewSnake,NewFood)
% Verifica se a cauda colidiu com a comida e a incrementa e 
% remove a comida
runSnake(Snake,Food,NewSnake,NewFood) :-
        colideTail(Food,Snake),
        addSnakeNode(Snake,NewSnake),
        removeFoodNode(Food,NewFood).
runSnake(Snake,Food,Snake,Food).

% run/4  - run(Snake,Food,NewSnake,NewFood)
% Executa as regras em ordem e retorna uma nova Lista de Snake e Food

% Retorna Listas vazias caso a Snake tenha colidido na parede
run(Snake,_,[],[]) :-
    colideWall(Snake),!.

% Retorna Listas vazias caso a Snake tenha colidido em si mesma
run(Snake,_,[],[]) :-
    colideSnake(Snake,Snake),!.

run(Snake,Food,NewSnake,NewFood) :-
    runFood(Snake,Food,TempFood),
    runSnake(Snake,TempFood,TempSnake,NewFood),
    changeAllSnake(TempSnake,NewSnake).

% setFood/1 :- setFood(Food)
% Seta estaticamente o predicado food/1
setFood(Food) :-
    retract(food(_)),
    assert(food(Food)).

% setSnake/1 - setSnake(Snake)
% Seta estaticamente o predicado snake/1
setSnake(Snake) :-
    retract(snake(_)),
    assert(snake(Snake)).

% setDirection/1 - setDirection(Direction)
% Determina nova direção da Snake 
setDirection(Direction) :-
    retract(direction(head,_)),
    assert(direction(head,Direction)).

% game/2 - game(Snake,Food)
% Função utilizada para "jogar"
game(Snake,Food) :-
    run(Snake,Food,NewSnake,NewFood),
    setFood(NewFood),
    setSnake(NewSnake),
    limit(LimitX,_),
    createMatrix(NewSnake,NewFood,[],LimitX,List),
    print(List).
    
% Iniciando o predicado food/1 na execução
resetFood:-  food([]),
    snake(Snake),
    randomFood(Snake,X,Y), 
    setFood([[X,Y]]).

:- resetFood.

% display/0 - display
% Fato necessário para iniciar glutDisplayFunc do plOpenGL
display.

% idle/0 - idle
% Regra que será chamada a cada iteração do programa
idle :- 
    clear,
    snake(Snake),food(Food),
    game(Snake,Food),
    sleep(0.2).
% keyboard/3 - keyboard(Asccii,X,Y)
% Mapeia os digitos do teclado para alguma ação

% tecla Esc finaliza a janela
% consequentemente finalizando o programa
keyboard(Key,_,_) :-
    key(Key,esc),
    glutDestroyWindow, !.

% Reseta o jogo
keyboard(Key,_,_) :-
    key(Key,restart),
    resetFood,
    startSnake(Snake),
    setSnake(Snake),
    setDirection(right).

% Para demais teclas, se a tecla digitada corresponder a 
% uma tecla de ação (up,left,down,right), verifica se a
% mudança é permitida e seta a direção
keyboard(X,_,_) :-
    direction(X,Direction),
	snake(Snake),
	snakeHead(Snake,LastDirection),
    allowed(LastDirection,Direction),
	setDirection(Direction).

% main/0 - main
% Função principal de um programa openGl
% Cria uma janela, inicializa listener do teclado,
% Gera loop  de execução
main :- 
    glutInit, 
    glutInitWindowSize(1, 1),
    glutCreateWindow('Snakes'),
    glutKeyboardFunc,
    glutIdleFunc(idle),
    glutDisplayFunc,
    glutMainLoop.
