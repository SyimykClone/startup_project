# ARound Database

SQL-скрипты схемы и начальных данных проекта ARound. Рабочая база данных проекта размещена в Supabase.

## SQL-файлы

- `feature/database/init.sql` - базовая схема и справочные данные
- `feature/database/seed.sql` - начальные данные по локациям
- `feature/database/users.sql` - таблицы пользователей и авторизации
- `feature/database/profile.sql` - данные профиля

## Как применять скрипты

Можно использовать один из вариантов:

1. SQL Editor в Supabase
2. Миграции Supabase
3. Любой PostgreSQL-клиент, подключенный к базе Supabase

Рекомендуемый порядок применения:

1. `init.sql`
2. `users.sql`
3. `profile.sql`
4. `seed.sql`

## Примечания

- Backend подключается к Supabase через `DATABASE_URL` из `feature/backend/.env`.
- Если схема базы меняется, обновляйте SQL-скрипты в этом каталоге, чтобы репозиторий оставался актуальным.
- `seed.sql` можно не применять в production, но он полезен для разработки, тестов и демонстрации проекта.
