# Doces e Contas

Jogo 2D de matemática em Godot 4.7.2. Resolva contas de adição, subtração, multiplicação ou divisão e acerte o doce com o martelo usando clique, toque ou arrasto. Os doces, os valores das respostas, o cronômetro, os pontos, os recordes, os combos e as dificuldades continuam integrados à mesma partida.

## Abrir e editar

Abra esta pasta no Godot pela Steam. F5 inicia pelo menu; F6 abre a cena que estiver selecionada. As cenas do menu, preparação, opções e jogo ficam em `scenes/`. Edite os pontos de surgimento em `CandySpawnPoints`, o atlas de doces em `assets/candy_atlas.svg`, o martelo em `assets/candy_hammer.svg` e o cenário em `assets/candy_arena.svg`. O tamanho do martelo e a área de acerto são ajustáveis no Inspector da cena do jogo.

Fácil dura 75 segundos, usa contas menores e doces mais lentos, e tira pouco tempo por erro. Normal dura 60 segundos e tira 3 segundos por erro. Difícil dura 45 segundos, usa contas mais avançadas, doces mais rápidos e uma penalidade maior. O menu de pausa mantém as opções de música, efeitos, dicas e tela cheia. Recorde e preferências ficam em `user://ninja_matematica.cfg`.

## API Project Gauss

No executavel nativo, defina `GAUSS_API_URL` (por exemplo, `http://127.0.0.1:3001`) e `GAUSS_API_TOKEN` de aluno para carregar contas e enviar tentativas à API. Na versão Web dentro do site, o jogo usa a sessão já salva em `localStorage` (`gauss.student.session`) e a URL da API configurada pelo site; o token não vai na URL. Sem token, a partida funciona offline e usa geração local com os mesmos conjuntos e faixas de dificuldade definidos em `project-gauss-api/src/learning/free-practice.ts`, mas as tentativas não são sincronizadas. A API identifica o jogo como `ninja-matematica`. A dificuldade seleciona um conjunto por operação e avança conforme a pontuação. O recorde e a duração da partida continuam salvos localmente porque a API não oferece um endpoint de sessão para esses dados.

## Acessibilidade e regressão

Além do martelo visual, pressionar `Tab` mostra as mesmas alternativas como botões. O jogo oferece **Ouvir / F1** para ler a pergunta, alternativas, retorno e orientação, e **Parar / F3** para interromper a leitura. Pausar, encerrar a rodada ou sair também interrompe a fala.

Da raiz do repositório, `bash scripts/run_accessibility_tests.sh` executa os percursos de teclado, leitura, feedback, pausa, foco, contraste e texto ampliado. A mesma bateria roda no GitHub Actions em pull requests e pushes para `main`.

## Abertura nativa do jogo

A logo (`assets/ui/esmague-os-documeros-logo.png`) e a imagem de abertura (`assets/ui/esmague-os-documeros-splash.png`) pertencem a este projeto. A abertura usa fundo azul escuro `#08101c`, logo centralizada e escala proporcional, configurados em `project.godot`, na seção `application/boot_splash` (Godot: **Project Settings → Application → Boot Splash**). A arte original fica preservada no arquivo de logo; a abertura usa margens proporcionais e considera a área visível da imagem.

A exportação Web padrão da Godot gera a imagem e o fundo a partir dessas configurações; não é necessário substituir `index.png` ou editar o HTML depois de exportar. Publique os arquivos gerados juntos, mantendo o fluxo de integração próprio do jogo. O menu e a mecânica permanecem independentes desta tela de carregamento.

Para reconstruir a imagem após trocar a logo aprovada:

```sh
godot --headless --path . --script res://tools/build_boot_splash.gd
```

O gerador usa somente os arquivos deste repositório, limita a arte a 1000 × 500 px em uma tela de 1920 × 1080 e não amplia a logo além da resolução original.
