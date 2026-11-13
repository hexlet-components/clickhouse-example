# Тонкий прокси: make <задача> запускает mise run <задача>. Задачи живут в mise.toml.
%: FORCE
	@mise run $@

# Без этого правила make пытается собрать сам Makefile через прокси.
Makefile: ;
FORCE: ;
