# Git Mastery Knowledge Base

## Propósito
Conocimiento experto de Git avanzado que se inyecta en agents durante /genesis.
Este conocimiento aplica a TODOS los proyectos.

---

## Modelo Mental de Git

```
┌─────────────────────────────────────────────────────────────┐
│                    REMOTE (origin)                          │
│                    ─────────────────                        │
│   Repositorio compartido (GitHub, GitLab, etc.)             │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │ push / fetch
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL REPOSITORY                         │
│                    ─────────────────                        │
│   .git/ → Historia completa de commits                      │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │ commit
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    STAGING AREA (Index)                     │
│                    ─────────────────────                    │
│   Cambios preparados para el próximo commit                 │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │ add
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    WORKING DIRECTORY                        │
│                    ─────────────────────                    │
│   Archivos que ves y editas                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Branches y Referencias

### HEAD
```bash
# HEAD = donde estás ahora
# Normalmente apunta a un branch
HEAD → main → commit abc123

# Detached HEAD = apunta directo a commit
HEAD → commit abc123
```

### Referencias relativas
```bash
HEAD~1    # Un commit atrás
HEAD~3    # Tres commits atrás
HEAD^     # Padre del commit (igual que ~1)
HEAD^2    # Segundo padre (en merges)

# Ejemplos
git show HEAD~2        # Ver commit de hace 2
git reset --soft HEAD~1  # Deshacer último commit
```

---

## Rebase

### Cuándo usar
```
✓ Limpiar historia antes de PR
✓ Actualizar feature branch con main
✓ Squash commits de work-in-progress

✗ NUNCA en branches públicos/compartidos
✗ NUNCA en main/develop
```

### Rebase simple
```bash
# Antes
main:     A---B---C
               \
feature:        D---E

# git checkout feature && git rebase main

# Después
main:     A---B---C
                   \
feature:            D'---E'
```

### Interactive rebase
```bash
git rebase -i HEAD~4

# Editor muestra:
pick abc123 Add feature X
pick def456 Fix typo
pick ghi789 WIP
pick jkl012 Finish feature

# Opciones:
# pick   = usar commit
# reword = cambiar mensaje
# edit   = pausar para modificar
# squash = combinar con anterior
# fixup  = squash sin mensaje
# drop   = eliminar commit

# Resultado común (squash WIP):
pick abc123 Add feature X
fixup def456 Fix typo
fixup ghi789 WIP
reword jkl012 Complete feature X
```

### Resolver conflictos en rebase
```bash
# Git pausa cuando hay conflicto
# 1. Resolver conflictos en archivos
# 2. Marcar resuelto
git add <archivo>
# 3. Continuar
git rebase --continue

# O abortar
git rebase --abort
```

---

## Cherry-pick

### Cuándo usar
```
✓ Aplicar hotfix de main a develop
✓ Traer commit específico sin merge
✓ Recuperar trabajo de branch abandonado
```

### Uso básico
```bash
# Aplicar un commit específico
git cherry-pick abc123

# Aplicar rango de commits
git cherry-pick abc123..def456

# Sin commitear automáticamente
git cherry-pick -n abc123
```

### Resolver conflictos
```bash
# Igual que rebase
git add <archivo>
git cherry-pick --continue

# O abortar
git cherry-pick --abort
```

---

## Bisect

### Qué es
Búsqueda binaria para encontrar el commit que introdujo un bug.

### Uso manual
```bash
# Iniciar
git bisect start

# Marcar commit malo (actual)
git bisect bad

# Marcar commit bueno conocido
git bisect good v1.0.0

# Git checkout automáticamente al punto medio
# Testear, luego marcar:
git bisect good  # Si funciona
git bisect bad   # Si tiene el bug

# Repetir hasta encontrar el culpable
# Git muestra: "abc123 is the first bad commit"

# Terminar
git bisect reset
```

### Uso automatizado
```bash
# Con script que retorna 0=good, 1=bad
git bisect start HEAD v1.0.0
git bisect run npm test

# Git ejecuta automáticamente hasta encontrar
```

---

## Reflog

### Qué es
Historial de donde ha estado HEAD. Tu seguro de vida en Git.

### Uso
```bash
# Ver reflog
git reflog

# Output:
# abc123 HEAD@{0}: commit: Add feature
# def456 HEAD@{1}: rebase: checkout main
# ghi789 HEAD@{2}: commit: WIP (antes del rebase)

# Recuperar estado anterior
git reset --hard HEAD@{2}

# O crear branch desde estado antiguo
git branch recovery HEAD@{5}
```

### Escenarios de rescate
```bash
# "Perdí commits después de rebase"
git reflog
# Buscar el commit antes del rebase
git reset --hard HEAD@{N}

# "Borré branch por error"
git reflog
# Buscar último commit del branch
git branch recovered HEAD@{N}

# "reset --hard eliminó mi trabajo"
git reflog
git reset --hard HEAD@{1}
```

---

## Stash

### Uso básico
```bash
# Guardar cambios temporalmente
git stash

# Con mensaje
git stash push -m "WIP: feature X"

# Listar stashes
git stash list
# stash@{0}: On main: WIP: feature X
# stash@{1}: On feature: debugging

# Aplicar y mantener en lista
git stash apply stash@{0}

# Aplicar y remover de lista
git stash pop

# Ver contenido
git stash show -p stash@{0}
```

### Stash parcial
```bash
# Solo algunos archivos
git stash push -m "message" file1.js file2.js

# Interactivo (por hunks)
git stash push -p
```

### Crear branch desde stash
```bash
git stash branch new-branch stash@{0}
```

---

## Reset vs Revert vs Checkout

### Comparación
```
┌─────────────┬─────────────────────────────────────────────┐
│ Comando     │ Qué hace                                    │
├─────────────┼─────────────────────────────────────────────┤
│ reset       │ Mueve HEAD y (opcionalmente) modifica       │
│             │ staging/working directory                   │
├─────────────┼─────────────────────────────────────────────┤
│ revert      │ Crea NUEVO commit que deshace cambios       │
│             │ (seguro para branches públicos)             │
├─────────────┼─────────────────────────────────────────────┤
│ checkout    │ Cambia working directory sin mover HEAD     │
│             │ (para explorar/recuperar archivos)          │
└─────────────┴─────────────────────────────────────────────┘
```

### Reset modes
```bash
# --soft: Solo mueve HEAD, mantiene staging y working
git reset --soft HEAD~1
# Uso: "Quiero rehacer el commit"

# --mixed (default): Mueve HEAD, limpia staging, mantiene working
git reset HEAD~1
# Uso: "Quiero re-organizar qué commitear"

# --hard: Mueve HEAD, limpia staging Y working
git reset --hard HEAD~1
# Uso: "Quiero descartar todo" (PELIGROSO)
```

### Cuándo usar cada uno
```bash
# Deshacer último commit privado (no pusheado)
git reset --soft HEAD~1

# Deshacer commit público (ya pusheado)
git revert HEAD  # Crea commit inverso

# Recuperar archivo de otro commit
git checkout abc123 -- path/to/file

# Descartar cambios locales de un archivo
git checkout -- path/to/file
```

---

## Merge Strategies

### Tipos de merge
```bash
# Fast-forward (si es posible)
# Simplemente mueve el pointer
git merge feature
#     main ────────────► feature

# No fast-forward (forzar merge commit)
git merge --no-ff feature
#     main ──────┬──────► merge commit
#                └───────►feature

# Squash (combinar en un commit)
git merge --squash feature
git commit -m "Add feature X"
```

### Cuándo usar cada uno
```
Fast-forward:     Features pequeños, historia lineal
--no-ff:          Preservar que hubo un feature branch
--squash:         Limpiar historia, ocultar commits intermedios
```

### Resolver conflictos
```bash
# Ver archivos en conflicto
git status

# En el archivo:
<<<<<<< HEAD
código de tu branch
=======
código del otro branch
>>>>>>> feature

# 1. Editar manualmente, elegir qué mantener
# 2. Eliminar marcadores (<<<<, ====, >>>>)
# 3. Marcar resuelto
git add <archivo>
# 4. Completar merge
git commit
```

---

## Worktrees

### Qué son
Múltiples working directories del mismo repo.

### Uso
```bash
# Crear worktree
git worktree add ../feature-x feature-x

# Listar
git worktree list

# Remover
git worktree remove ../feature-x

# Limpiar huérfanos
git worktree prune
```

### Casos de uso
```
✓ Trabajar en múltiples features simultáneamente
✓ Compilar branch diferente sin cambiar
✓ Tener ambiente de QA separado
✓ Comparar versiones lado a lado
```

---

## Hooks

### Hooks útiles
```bash
# pre-commit: Antes de commit
#!/bin/sh
npm run lint
npm run test

# commit-msg: Validar mensaje
#!/bin/sh
if ! grep -qE "^(feat|fix|docs|refactor): " "$1"; then
  echo "Commit message must start with type:"
  exit 1
fi

# pre-push: Antes de push
#!/bin/sh
npm run test:all
```

### Ubicación
```
.git/hooks/           # Local (no commiteable)
.husky/               # Con husky (commiteable)
```

---

## Comandos de Diagnóstico

### Ver historia
```bash
# Historia gráfica
git log --oneline --graph --all

# Historia de un archivo
git log --follow -p -- path/to/file

# Quién modificó cada línea
git blame path/to/file

# Buscar en historia
git log -S "función_buscada"
git log --grep="bug fix"
```

### Ver diferencias
```bash
# Working vs Staging
git diff

# Staging vs Last commit
git diff --staged

# Entre commits
git diff abc123..def456

# Entre branches
git diff main..feature
```

### Estado
```bash
# Estado completo
git status

# Solo archivos cambiados
git status -s

# Remotes
git remote -v

# Branches y tracking
git branch -vv
```

---

## Patrones Seguros

### Antes de operación peligrosa
```bash
# Crear backup branch
git branch backup-before-rebase

# Verificar que puedes recuperar
git reflog  # Siempre funciona

# Proceder con operación
git rebase -i HEAD~5
```

### Recuperación
```bash
# Ver qué pasó
git reflog

# Volver a estado anterior
git reset --hard HEAD@{N}

# O desde backup
git reset --hard backup-before-rebase
```

---

## Checklist de Git

### Antes de commit
- [ ] `git status` - verificar qué se incluye
- [ ] `git diff --staged` - revisar cambios
- [ ] Mensaje sigue convención del proyecto

### Antes de push
- [ ] `git log origin/main..HEAD` - ver qué se pushea
- [ ] Tests pasan localmente
- [ ] No hay secrets en commits

### Antes de merge a main
- [ ] Branch actualizado con main
- [ ] Conflicts resueltos
- [ ] PR aprobado
- [ ] CI verde

### Si algo sale mal
- [ ] NO panic, NO `--force` inmediato
- [ ] `git reflog` para ver historia
- [ ] Crear backup branch si es necesario
- [ ] Investigar antes de actuar
