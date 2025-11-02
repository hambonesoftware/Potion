# Snippets

**Schedule Math (nextDue)**
- If cadenceDays: nextDue = (lastDoneAt ?? now) + cadenceDays
- If dayOfWeek: next = next weekday after (lastDoneAt ?? now)
- If dayOfMonth: clamp to month length

**Import Unknown Keys**
- For any key not in known map: custom[key] = String(describing: value)
