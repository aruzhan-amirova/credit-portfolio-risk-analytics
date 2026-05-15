# Credit Portfolio & Risk Analytics

Небольшой аналитический проект по кредитному портфелю банка/финтех-компании.

Я использую синтетические данные за период с января 2024 по апрель 2026 и разбираю путь клиента от подачи заявки до фактической выдачи кредита и дальнейших платежей. Основной фокус проекта — заявки, одобрения, выдачи, клиентские сегменты и ранняя просрочка.

## О проекте

Идея проекта — посмотреть на кредитный портфель не просто как на набор таблиц, а как на бизнес-процесс: клиент подаёт заявку, банк принимает решение, часть заявок превращается в кредиты, а дальше по этим кредитам появляются платежи и возможная просрочка.

Такой анализ помогает понять, как меняется поток заявок, насколько стабильно работает воронка одобрений и выдач, какие продукты дают больший объём и где может появляться повышенный риск.

## Данные

В проекте используется модель кредитного портфеля: клиенты, заявки, выданные кредиты и платежи.

`clients` хранит информацию о клиентах: город, дату рождения, доход, тип занятости и кредитный скоринг.  
`loan_applications` содержит заявки на кредит с датой, продуктом, запрошенной суммой и статусом.  
`loans` показывает только те заявки, которые дошли до фактической выдачи.  
`payments` хранит платежи по кредитам и количество дней просрочки.

Важно, что не каждая заявка становится кредитом: часть заявок отклоняется, часть одобряется, но не доходит до выдачи. А у одного кредита может быть много платежей, поэтому при расчёте просрочки данные по платежам нужно отдельно приводить к уровню одного кредита.

## Что анализирую

В первую очередь я смотрю на кредитную воронку: сколько заявок приходит каждый месяц, какая часть из них одобряется и сколько в итоге превращается в выданные кредиты.

Дальше анализ можно расширить по продуктам и клиентским сегментам: сравнить объём выдач, средний размер кредита, долю повторных клиентов и раннюю просрочку DPD30+.

Основные метрики проекта:

- количество заявок;
- количество одобренных заявок;
- количество выданных кредитов;
- сумма запрошенных средств;
- сумма выданных кредитов;
- approval rate;
- issue rate;
- DPD30+ rate.

## Инструменты

В проекте используются:

- PostgreSQL
- pgAdmin
- SQL
- Power BI
- DAX
- GitHub

На текущем этапе реализованы SQL-анализ, аналитические витрины для BI и Power BI dashboard.
Python EDA notebook планируется как следующий этап проекта.

## Структура проекта

Проект разбит на несколько частей:

- `data/` — исходные CSV-файлы;
- `sql/` — SQL-запросы для создания таблиц, проверки данных и анализа;
- `insights/` — короткие выводы по результатам анализа;
- `README.md` — описание проекта.

SQL-файлы разделены по смыслу: отдельно создание таблиц, отдельно проверки качества данных и отдельно аналитические запросы. Так проект проще читать и проверять.

## Уже сделано

На текущем этапе:

- создана структура базы данных;
- загружены данные за период с января 2024 по апрель 2026;
- добавлены связи между таблицами;
- написаны проверки качества данных;
- подготовлен первый SQL-запрос по месячной воронке заявок, одобрений и выдач;
- добавлен анализ DPD30+;
- добавлен vintage / MOB-анализ;
- добавлен анализ новых и повторных клиентов;
- добавлен анализ клиентских сегментов по credit_score;
- добавлена папка `insights/` с бизнес-выводами;
- подготовлены SQL views для Power BI dashboard;
- построен Power BI dashboard на 4 страницы:
  - Monthly Funnel
  - Product Risks
  - Client Segments
  - Vintage / MOB
- добавлены screenshots dashboard pages.

## Следующие шаги

Дальше планирую добавить:

- Python EDA notebook с первичным анализом данных;
- визуализации по заявкам, выдачам, credit_score, доходу и DPD30+;
- ER-диаграмму и data dictionary;
- BI-дашборд с ключевыми метриками по кредитному портфелю;
- скрипт генерации синтетических данных для воспроизводимости проекта.

  ## SQL-анализ

В проекте подготовлены следующие SQL-файлы:

- `01_create_tables.sql` — создание таблиц и связей;
- `02_data_quality_checks.sql` — проверки качества данных;
- `03_monthly_application_funnel.sql` — месячная воронка заявок;
- `04_monthly_product_funnel.sql` — воронка по кредитным продуктам;
- `05_dpd30_analysis.sql` — анализ DPD30+;
- `06_repeat_clients_analysis.sql` — анализ новых и повторных клиентов;
- `07_vintage_mob_analysis.sql` — vintage / MOB-анализ;
- `08_client_segment_analysis.sql` — анализ клиентских сегментов по credit_score.

## Power BI Dashboard

Power BI dashboard построен на основе PostgreSQL analytical views из файла `sql/09_powerbi_views.sql`.

Вместо подключения визуализаций напрямую к сырым таблицам, для dashboard были подготовлены отдельные BI-ready views:

| Dashboard page | SQL view | Purpose |
|---|---|---|
| Monthly Funnel | `bi_monthly_funnel` | Monthly application funnel: applications, approvals, issued loans, requested amount, issued amount, approval rate and issue rate |
| Product Risks | `bi_product_risk` | Product-level risk analysis: issued amount, DPD30+ loans, DPD30+ amount, DPD30+ loan rate and DPD30+ amount share |
| Client Segments | `bi_client_segments` | Client score segment analysis: client count, average credit score, income, issued amount and DPD30+ risk |
| Vintage / MOB | `bi_vintage_mob` | Vintage/MOB analysis of DPD30+ dynamics by vintage month and month-on-book |

Dashboard pages:

1. **Monthly Funnel** — динамика заявок, одобрений и выдач.
2. **Product Risks** — риск и выдачи по кредитным продуктам.
3. **Client Segments** — анализ score-сегментов клиентов.
4. **Vintage / MOB** — DPD30+ по месяцам выдачи и месяцам жизни кредита.

### Dashboard screenshots

#### Monthly Funnel
![Monthly Funnel](powerbi/screenshots/01_monthly_funnel.png)
#### Product Risks
![Product Risks](powerbi/screenshots/02_product_risks.png)
#### Client Segments
![Client Segments](powerbi/screenshots/03_client_segments.png)
#### Vintage / MOB
![Vintage MOB](powerbi/screenshots/04_vintage_mob.png)

## Key dashboard insights

- Application funnel shows the difference between submitted applications, approved applications and issued loans over time.
- Product risk analysis highlights products with higher DPD30+ loan rate and DPD30+ amount share.
- Client segment analysis shows how credit score groups differ by issued amount, average income and DPD30+ risk.
- Vintage/MOB matrix helps track how DPD30+ develops across months-on-book for different loan issue months.
