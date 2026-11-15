# Teclado na partida e retorno ao site

## Implementado

- Tab e Shift+Tab percorrem conta, respostas disponíveis e pausa, com foco visível. Enter/espaço na conta repete a leitura quando habilitada; nos botões confirma uma única resposta. O rótulo da conta e das respostas é textual.
- No modo doces, o primeiro Tab apresenta os controles estáticos já existentes, preservando questão e alternativas. Isso não envia tentativa, não modifica o perfil global e não altera a correção da API. O perfil com entrada preferida por teclado também usa esses controles.
- Enquanto uma tentativa aguarda confirmação, respostas ficam desabilitadas. Depois de erro, voltam a funcionar e o foco retorna à resposta selecionada. A mudança de questão continua seguindo o fluxo existente.
- Pausa e fim de rodada mantêm Tab em suas ações. HUD oculto e controles indisponíveis não entram no ciclo.
- A saída ao menu é bloqueada enquanto existir tentativa pendente. Se o aluno solicitar a saída durante pausa, o jogo retoma a espera/retry sem perder o payload.
- O menu tem novamente um botão real **SAIR**, com tema dourado, SVG, hover, foco por teclado e chave de narração. Ele envia `gauss-ninja-exit`, versão 1, ao host de mesma origem. Sem iframe do site, fica indisponível com explicação; não fecha o aplicativo/navegador.
- O site valida origem e janela remetente contra o iframe ativo. O retorno usa a origem guardada pelo site na abertura: Home retorna à Home e Prática retorna à lista de jogos. Não aceita URL ou rota enviada pelo jogo. O botão de retorno do cabeçalho usa o mesmo callback.
- Troféus continuam integrados e invisíveis no HUD. O modo sem limite mantém `TEMPO: ∞` e “Tempo sem limite” como rótulo acessível.

## Arquivos principais

`scripts/main.gd`, `scripts/menu.gd`, `scenes/menu.tscn`, `tests/keyboard_test.gd`, `tests/keyboard_game_stub.gd` e inventário `content/menu_narration_request.json`.

No site: `components/ninja-matematica-game.tsx`, `student-app.tsx` e o export `public/games/ninja-matematica`. API, Android e outros exports não foram modificados.

## Verificação

- Importação e exportação Godot 4.7.2 concluíram.
- `KEYBOARD_TEST: PASS`: eventos de teclado reais do Godot, Tab/ShiftTab, Enter e espaço com uma tentativa por ação, bloqueio enquanto pendente, preservação das alternativas e restauração de foco após erro, pausa/retomada, modal de fim de rodada e transição dos doces para controles estáticos da mesma questão.
- O teste usa uma subclasse isolada que captura tentativas em memória. Não registra respostas em banco. A cópia de validação omite apenas chamadas de voz nativa incompatíveis com este ambiente; o export foi gerado do projeto real.
- `HOST_EXIT_TEST: PASS`: executa os corpos reais dos callbacks do site com janela/eventos simulados. Rejeita origem errada, outra janela, tipo ou versão inválidos; valida limpeza do listener e retorno Home/Prática. Não substitui homologação do fluxo completo no navegador autenticado.
- `npm run typecheck -w @gauss/web`, `npm run build -w @gauss/web` e diff-check passaram. Build com aviso já existente de `node:module` em `ephone`; Godot com aviso ambiental de certificados.

Capturas em `C:/Users/kevim/AppData/Local/Temp/ninja-menu-review/`:

- `menu-exit-800.png` (visual de SAIR habilitado, simulando host na cópia de teste).
- `gameplay-equation-focus-800.png`.
- `gameplay-answer-focus-800.png`.

SHA-256 do novo `index.pck`: `84D079AE1E5E4DD465482172D521B648AC4F893760C55D184733E7B7205AB926`.

Richard fará a validação final no navegador. Não foi declarada acessibilidade integral nem gerado áudio; novas chaves/textos aguardam o fluxo central de voz. Sem commit ou push.
