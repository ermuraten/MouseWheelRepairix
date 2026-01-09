---
description: Git-Commits
---

Das heute als Industriestandard geltende Format für Git-Commits sind die Conventional Commits. Sie folgen einer festen Struktur, die sowohl für Menschen leicht lesbar ist als auch von Tools zur automatischen Erstellung von Changelogs genutzt werden kann. 
1. Die Grundstruktur (Conventional Commits)
Ein Commit sollte nach folgendem Schema aufgebaut sein:
Text

<Typ>(<Optionaler Bereich>): <Kurze Beschreibung>

[Optionaler Textkörper: Erklärt das "Warum" hinter der Änderung]

[Optionaler Footer: Referenziert Tickets oder "Breaking Changes"]
Wichtige Typen (Types):
feat: Eine neue Funktion für den Anwender.
fix: Ein Bugfix.
docs: Änderungen an der Dokumentation.
style: Formatierungen (Semantik bleibt gleich).
refactor: Code-Änderung ohne Bugfix oder neue Funktion.
chore: Wartungsarbeiten oder Build-Prozesse. 
2. Die „50/72-Regel“
Für eine optimale Darstellung in Tools wie GitHub oder dem Terminal sollten Sie diese Längenbegrenzungen einhalten: 
Betreffzeile: Maximal 50 Zeichen. Sie sollte mit einem Großbuchstaben beginnen und nicht mit einem Punkt enden.
Leerzeile: Zwischen Betreff und Textkörper muss zwingend eine Leerzeile stehen.
Textkörper: Jede Zeile sollte maximal 72 Zeichen lang sein. 
3. Best Practices für den Inhalt
Imperativ nutzen: Schreiben Sie den Betreff im Befehlston (z. B. fix: resolve bug statt fixed bug).
Das „Warum“ erklären: Der Code zeigt das „Wie“, die Nachricht sollte erklären, warum die Änderung nötig war.
Tickets verknüpfen: Referenzieren Sie Issue-IDs (z. B. Closes #123) im Footer, um die Historie nachvollziehbar zu machen. 
Beispiel eines perfekten Commits:
Text

feat(api): add user authentication endpoint

Introduce a new POST /auth/login endpoint to handle user 
authentication via JWT. This replaces the old session-based 
approach to support mobile clients better.

Closes #42
