# Ninja Matemática

Protótipo 2D inspirado na referência Fruit Ninja, feito em Godot 4.7.2. A cena principal tem fundo de madeira, seleção das quatro operações, equação, frutas cortáveis por mouse/toque, cronômetro, pontuação, sequência de acertos e recorde local.

## Abrir e editar

Importe esta pasta no Godot pela Steam e abra `scenes/main.tscn`. A árvore separa a cena principal, a fruta reutilizável, o HUD e os scripts. O fundo está em `assets/dojo_wood.png`; sua posição e escala ficam salvas diretamente no nó `Background`. Os pontos onde as frutas aparecem são nós `Marker2D` dentro de `FruitSpawnPoints`; mova esses marcadores no editor. O HUD e os quatro botões de operação também são nós editáveis na cena. A velocidade e o efeito de queda ficam exportados no nó `Main` e na cena da fruta.

Arraste o mouse ou deslize o dedo sobre as frutas. A rodada dura 40 segundos; uma resposta errada remove 3 segundos. A cada 120 pontos, o jogo sobe a dificuldade das contas e acelera as frutas. Clique numa operação para começar uma partida nova.

## API Project Gauss

Sem token, o jogo usa perguntas locais para facilitar a edição. Para registrar questões e tentativas de um aluno, defina as variáveis de ambiente `GAUSS_API_URL` (por exemplo `http://127.0.0.1:3001`) e `GAUSS_API_TOKEN` com um token de sessão de aluno e abra o jogo novamente. O jogo solicita perguntas ao endpoint de prática livre e envia cada corte para `/learning/attempts`; correção e histórico oficial vêm da API. O identificador estável deste jogo é `ninja-matematica`.

Esta integração registra questões e respostas. Depois de atualizar o código da API, execute `npm run db:seed` em `project-gauss-api` para publicar a compatibilidade do novo `gameId` nos conjuntos de prática. A API ainda não oferece um endpoint de sessão que persista pontuação total, recorde ou duração; esses dados ficam no jogo, com recorde local no aparelho.
