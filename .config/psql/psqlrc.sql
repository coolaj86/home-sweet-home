-- psql meta-commands: https://www.postgresql.org/docs/current/app-psql.html

--
-- Per-DB Configuration
--
\set HISTFILE ~/.config/psql/ :DBNAME /history
\set dbrc ~/.config/psql/ :DBNAME /psqlrc.sql
\if `mkdir -p :CONFDIR && chmod 0700 :CONFDIR && echo n || echo y`
    \echo [WARN] could not create :CONFDIR
    \set HISTFILE ~/.config/psql/history
\else
    \if `test -f :dbrc || touch :dbrc && chmod 0600 :dbrc && echo n || echo y`
        \echo [WARN] could not create :dbrc
    \else
        \echo loading :dbrc
        \i :dbrc
    \endif
    \if `test -f :HISTFILE || touch :HISTFILE && chmod 0600 :HISTFILE && echo n || echo y`
        \echo [WARN] could not create :HISTFILE
        \set HISTFILE ~/.config/psql/history
    \endif
\endif
\unset :dbrc

--
-- Session Preferences
--
-- ignore space-prefixed commands and duplicates
\echo using :HISTFILE for command history

\set QUIET on
\set HISTCONTROL ignoreboth
\set ON_ERROR_ROLLBACK interactive
\set COMP_KEYWORD_CASE upper
\pset pager off
\pset null '(null)'
SET TIME ZONE 'America/Denver';
\unset QUIET

\echo ''
\x
