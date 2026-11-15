# Série confirmada antes de abrir a preparação

Ao clicar em Jogar, o menu consulta a série pelo endpoint existente `/learning/lessons`. O botão mostra AGUARDE... durante a consulta; a preparação só é aberta após uma resposta válida. Não há atraso artificial fixo.

A série é transferida em memória e consumida uma única vez pela preparação. O menu limpa esse valor ao abrir novamente. Antes do primeiro quadro da preparação, ano 1/2 já bloqueia multiplicação/divisão e ano 3 ou superior já libera ambos. Não há consulta repetida na preparação nem elegibilidade provisória.

A consulta tem timeout de 10 segundos. Falha de rede, série inválida ou sessão ausente mantém o menu, restaura os controles e oferece TENTAR NOVAMENTE com descrição acessível. O botão Sair continua funcionando durante a espera. Abrir preparação sem os dados da transição retorna ao menu.

Validação local com cenas reais: anos 1, 3 e 5 já tinham estados corretos logo após `_ready`; o valor em memória foi consumido; sessão ausente restaurou Jogar para tentar novamente. Resultado PREPARATION_FIRST_FRAME: PASS. Não foi usado banco nem registrada tentativa. O timeout foi configurado, mas não foi simulado nesse teste. Export Web regenerado; o percurso autenticado no navegador ainda deve ser conferido.