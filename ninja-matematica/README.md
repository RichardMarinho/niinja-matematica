# Ninja Matematica

Prototipo 2D inspirado no Fruit Ninja, feito em Godot 4.7.2. O menu inicial oferece **Jogar**, **Opcoes** e **Sair**. Na preparacao da partida, escolha Facil, Normal ou Dificil e marque uma ou mais operacoes. O jogo mostra uma conta; corte a fruta com a resposta certa usando o mouse ou a tela de toque.

## Abrir e editar

Importe esta pasta no Godot pela Steam e execute o projeto: `scenes/menu.tscn` e a cena inicial, com os elementos do menu como nos editaveis. Abra `scenes/menu.tscn` no painel FileSystem para editar titulo, botoes, HUD e fundo; as outras cenas editaveis sao `scenes/preparation.tscn`, `scenes/options.tscn` e `scenes/game.tscn`. `scenes/main.tscn` continua disponivel como instancia editavel do menu. F5 inicia o projeto pelo menu. F6 executa a cena atualmente aberta. O fundo ilustrado do menu fica em `assets/menu_background.png`. Na partida, mova os nos `Marker2D` dentro de `FruitSpawnPoints` para mudar de onde as frutas aparecem. Os fundos sao nos estaticos chamados `Background`; ajuste posicao e escala no editor.

Facil dura 75 segundos, usa contas menores, frutas mais lentas e tira 1 segundo por erro. Normal dura 60 segundos e tira 3 segundos por erro. Dificil dura 45 segundos, aumenta a complexidade e a velocidade das frutas, e tira 5 segundos por erro. O botao Pausar abre as opcoes para continuar, ajustar musica/efeitos/dicas/tela cheia ou voltar ao menu. Quando o tempo acaba, aparece a tela de derrota com as opcoes de tentar novamente ou sair ao menu. Preferencias, selecao da partida e recorde ficam em `user://ninja_matematica.cfg`.

## API Project Gauss

Sem token, o jogo usa perguntas locais. Para registrar perguntas e tentativas de um aluno, defina `GAUSS_API_URL` (por exemplo, `http://127.0.0.1:3001`) e `GAUSS_API_TOKEN` com um token de sessao de aluno antes de abrir o jogo. O jogo solicita perguntas a API de pratica livre e envia os cortes para `/learning/attempts`. O identificador do jogo e `ninja-matematica`.

A integracao registra questoes e respostas. A API ainda nao oferece um endpoint de sessao que persista pontuacao total, recorde ou duracao; o recorde fica salvo localmente.
