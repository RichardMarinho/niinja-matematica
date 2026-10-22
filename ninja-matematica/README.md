# Doces e Contas

Jogo 2D de matemática em Godot 4.7.2. Resolva contas de adição, subtração, multiplicação ou divisão e acerte o doce com o martelo usando clique, toque ou arrasto. Os doces, os valores das respostas, o cronômetro, os pontos, os recordes, os combos e as dificuldades continuam integrados à mesma partida.

## Abrir e editar

Abra esta pasta no Godot pela Steam. F5 inicia pelo menu; F6 abre a cena que estiver selecionada. As cenas do menu, preparação, opções e jogo ficam em `scenes/`. Edite os pontos de surgimento em `CandySpawnPoints`, o atlas de doces em `assets/candy_atlas.svg`, o martelo em `assets/candy_hammer.svg` e o cenário em `assets/candy_arena.svg`. O tamanho do martelo e a área de acerto são ajustáveis no Inspector da cena do jogo.

Fácil dura 75 segundos, usa contas menores e doces mais lentos, e tira pouco tempo por erro. Normal dura 60 segundos e tira 3 segundos por erro. Difícil dura 45 segundos, usa contas mais avançadas, doces mais rápidos e uma penalidade maior. O menu de pausa mantém as opções de música, efeitos, dicas e tela cheia. Recorde e preferências ficam em `user://ninja_matematica.cfg`.

## API Project Gauss

No executavel nativo, defina `GAUSS_API_URL` (por exemplo, `http://127.0.0.1:3001`) e `GAUSS_API_TOKEN` de aluno para carregar contas e enviar tentativas à API. Na versão Web dentro do site, o jogo usa a sessão já salva em `localStorage` (`gauss.student.session`) e a URL da API configurada pelo site; o token não vai na URL. Sem token, a partida funciona offline e usa geração local com os mesmos conjuntos e faixas de dificuldade definidos em `project-gauss-api/src/learning/free-practice.ts`, mas as tentativas não são sincronizadas. A API identifica o jogo como `ninja-matematica`. A dificuldade seleciona um conjunto por operação e avança conforme a pontuação. O recorde e a duração da partida continuam salvos localmente porque a API não oferece um endpoint de sessão para esses dados.
