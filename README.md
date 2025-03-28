# hse-se-dwh-hw-2024-komarov
_Хранилище данных для системы управления перелетами между аэропортами._

Перед запуском нужно убедиться, что у запускаемых `.sh`-скриптов стоит тип разделителя 
`LF`, иначе могут возникнуть ошибки.

Запуск осуществляется командой `docker compose up -d` из корня проекта:
```shell
docker compose up -d
```

1. В `postgres_master` поступают данные из инициализирующего скрипта;
2. `postgres_slave` реплицирует данные;
3. Поднимается `debezium` с `kafka`; 
4. `connector` создает коннекторы для записи в `kafka` из `postgres_master` и чтения из `kafka` с
последующей записью в схему `raw` базы `vertica_dwh`;
5. Поднимается кластер `airflow`;
6. В нем автоматически запускаются `DAG`'и (директория `/dags`),
реализованные при помощи инструмента `dbt` (модели лежат в директории `/dbt` и монтируются в кластер):
   - `dag_dwh.py` - складывает данные из схемы `raw` в схему `dwh` по якорной модели, каждые 5 минут;
   - `dag_dbt_airports_traffic_mart.py` - собирает витрину из схемы `dwh` пассажиропотока 
из аэропорта/в аэропорт по дням, раз в сутки, складывает в схему `presentation`;
   - `dag_frequent_flyers_mart.py` - собирает витрину из схемы `dwh` самых активных пассажиров,
раз в сутки, складывает в схему `presentation`;\
   Для просмотра надо перейти по `localhost:8084/home`.
7. Запускается `vertica-exporter`, собранный из образа с официального 
[github](https://github.com/vertica/vertica-prometheus-exporter) `vertica`,
который экспортирует метрики из хранилища и передает в `prometheus`;
8. Запускается `prometheus`, уже подключенный к `vertica-exporter`;
9. Запускается `grafana`, в ней два подключения: `prometheus` и `vertica_dwh`, а также два дэшборда:
   (монтируются из папки `/dashboards`). \
   Для просмотра надо перейти по `localhost:3000/dashboards`.

## Для организации работы системы используются следующие контейнеры со следующим функционалом в системе:

## `postgres_master`
Основная `postgres:14.5`-система-источник куда поступают бизнес-данные. \
Ее внутреннее устройство описано в монтированной файле `init-postgres.sql`, где создаются таблицы и
проливается небольшое количество тестовых данных, чтобы не грузить систему. \
В скрипте `init-scrtpt/init.sh` создается пользователь для реплики, вызывается `pq_basebackup` для
резервного копирования и копируются необходимые директории для `master` и `slave`. \
Доступна на порте `5432`.

## `postgres_slave`
Идентичная реплика основной базы. Ожидает успешного состояния `master`'а `healthy` и поднимается, 
устанавливая с ней связь для синхронизации.\
Доступна на порте `5434`.

## `vertica_dwh`
Data Warehouse на основе `single-node vertica`, в которой данные хранятся по архитектуре 
`Anchor Modelling`. \
Используется модифицированный `vertica-ce`-образ: удалена инициализация тестовой базой `vmart`,
а так же создается три схемы: \
`raw` - для приезжающих данных из источников, \
`dwh` - для хранения разложенных данных и \
`presentation` - для витрин и визуализаций. \
Используемый готовый `docker`-образ лежит в директории `vertica-novmart`, его можно собрать 
самостоятельно и заменить образ контейнера в `docker-compose`, если нет возможности подключения к 
`docker-hub`. \
Доступна на порте `5433`.

## `zookeeper`
Классический образ координатора, необходимый для работы кластера брокеров `apache-kafka`. \
Доступен на порте `2181`.

## `broker`
Основной брокер, управляющий очередями сообщений. Подключен к `zookeeper`. \
Доступен на портах:\
`9092` для локального хоста, \
`29092` для сети `docker`,\
`9091` для JMX-мониторинга.

## `debezium`
`Kafka Connect` с установленным `debezium`. 
Слушает изменения в `postgres_master` и передает их в `Kafka`. \
Замонтированная директория `vertica-plugin` содержит необходимый драйвер для `vertica` от 
`confluentinc`. \
Ожидает успешного запуска `postgres_master` и `broker`. \
Доступен на порту `8083`.

## `debezium-ui`
Веб-интерфейс для удобной работы с коннекторами. \
Ожидает успешного запуска `debezium`. \
Доступен на порту `8080`.

## `schema-registry`
Используется для хранения сообщений очереди в форматах Avro/Proto. \
Ожидает успешного запуска `broker`. \
Доступна на порту `8081`.

## `rest-proxy`
Позволяет взаимодействовать с `kafka` через `REST API`. \
Ожидает успешного запуска `broker`. \
Доступен на порту `8082`.

## `connector`
`Debian`-контейнер, осуществляет необходимые подключения для `debezium`. \
Замонтированный скрипт `start-connectors.sh`, используя `curl`, отправляет `POST`-запросы для создания 
коннекторов на сервер `debezium`:\
один для чтения всех таблиц в `postgres_master`, создающий топики в `kafka` \
и по `sink`-коннектору для каждого топика, которые пишут изменения в соответствующие таблицы схемы
`raw` хранилища `vertica_dwh`. \
Используемые конфигурации коннекторов находятся в директории `/connectors`.
После отправления запросов контейнер завершает работу. \
Ожидает успешного запуска `debezium`. \
Контейнер недоступен для подключения по порту.

## `postgres-airflow`
Внутренняя база `airflow` для хранения метаданных. \
Контейнер недоступен для подключения по порту.

## `redis`
Брокер задач для `celery`, передающих между компонентами кластера `airflow`. \
Доступен на порту `6379`.

\
_Все контейнеры кластера `airflow` объединены общим конфигом, обозначенным `airflow-common`._ \
_Это модифицированный `apache/airflow:2.10.5` с предустановленным `dbt` и драйвером для `vertica`._ \
_В нем устанавливаются необходимые переменные среды, а также монтируются конфиг, логи, `DAG`'и, 
модели `dbt` и плагины._ \
_Образ находится в директории `/airflow-vertica`._
## `airflow-webserver`
Веб-интерфейс для управления кластером `airflow`. \
Ожидает успешного запуска `redis`, `postgres-airflow` и  `airflow-init`. \
Доступен на порту `8084`.

## `airflow-scheduler`
Планировщик задач, отслеживающий и запускающий `DAG`'и.
Ожидает успешного запуска `redis`, `postgres-airflow` и  `airflow-init`. \
Контейнер недоступен для подключения по порту.

## `airflow-worker`
Обработчик задач в Celery (используется для выполнения задач в `DAG`'ах).
Ожидает успешного запуска `redis`, `postgres-airflow` и  `airflow-init`. \
Контейнер недоступен для подключения по порту.

## `airflow-triggerer`
Контейнер для обработки асинхронных задач.
Ожидает успешного запуска `redis`, `postgres-airflow` и  `airflow-init`. \
Контейнер недоступен для подключения по порту.

## `airflow-init`
Контейнер для инициализации учетной записи и базы данных для старта кластера. \
Ожидает успешного завершения `connector`. \
Контейнер недоступен для подключения по порту.

## `airflow-cli`
Контейнер с командной строкой для взаимодействия с Airflow. \
Недоступен для подключения по порту.

## `grafana`
Интерфейс для визуализации данных из `Prometheus`. \
Ожидает `healthy` от `airflow-webserver`. \
Доступна по порту `3000`.

## `prometheus`
Система мониторинга и сбора метрик. \
Ожидает `healthy` от `airflow-webserver`. \
Доступен по порту `9090`.

## `vertica-exporter`
Экспорт метрик из `vertica` в `prometheus`. \
Ожидает `healthy` от `airflow-webserver`. \
Доступен по порту `9968`.

## Запросы для создания дэшбордов:
###  Аналитический дэшборд по аэропортам:
1. Цифра - всего активных аэропортов
  ```sql
  SELECT COUNT(airport_code) AS active_airports
  FROM presentation.airports_traffic
  WHERE flight_date::DATE >= NOW() - INTERVAL '30 days'
    AND (flights_in > 0 OR flights_out > 0);
  ```
2. График - всего активных аэропортов
  ```sql
  SELECT flight_date::DATE, COUNT(DISTINCT airport_code) AS active_airports
  FROM presentation.airports_traffic
  WHERE flight_date::DATE >= NOW() - INTERVAL '30 days'
    AND (flights_in > 0 OR flights_out > 0)
  GROUP BY flight_date::DATE
  ORDER BY flight_date::DATE;
  ```
3. Pie-chart - доля аэропортов в совокупном пассажиропотоке
  ```sql
  SELECT airport_code, 
         SUM(passengers_in + passengers_out) AS total_passengers
  FROM presentation.airports_traffic
  WHERE flight_date::DATE >= NOW() - INTERVAL '30 days'
  GROUP BY airport_code;
  ```
4. Pie-chart - доля аэропортов в общем кол-ве рейсов
  ```sql
  SELECT airport_code, 
         SUM(flights_in + flights_out) AS total_flights
  FROM presentation.airports_traffic
  WHERE flight_date::DATE >= NOW() - INTERVAL '30 days'
  GROUP BY airport_code;
  ```

### Аналитический дэшборд по пассажирам
1. Цифра - всего уникальных пассажиров за последние 30 дней
```sql
SELECT COUNT(DISTINCT passenger_id) AS unique_passengers
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days';
```
2. Цифра - средний чек за последние 30 дней
```sql
SELECT AVG(purchase_sum) AS avg_ticket_price
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days';
```
3. Цифра - среднее кол-во перелетов на пассажира за последние 30 дней
```sql
SELECT AVG(flights_number) AS avg_flights_per_passenger
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days';
```
4. График - динамика кол-ва уникальных пассажиров по дням
```sql
SELECT DATE(created_at) AS flight_date, 
       COUNT(DISTINCT passenger_id) AS unique_passengers
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY flight_date
ORDER BY flight_date;
```
5. График - динамика совокупной выручки по дням
```sql
SELECT DATE(created_at) AS flight_date, 
       SUM(purchase_sum) AS total_gmv
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY flight_date
ORDER BY flight_date;
```
6. Pie chart - доля разных групп пассажиров (см. ДЗ №3) в GMV за последние 30 дней
```sql
SELECT customer_group, 
       SUM(purchase_sum) AS group_gmv
FROM presentation.frequent_flyers
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY customer_group;
```

## E/R-диаграмма для dwh
![E/R-диаграмма dwh vertica](er.png)


#### Источники вдохновения:
- https://habr.com/ru/companies/avito/articles/322510/
- https://www.anchormodeling.com/tutorials/
- https://habr.com/ru/companies/sberbank/articles/414895/
- https://ivan-shamaev.ru/dbt-clickhouse-tutorial-run-model-data/
- https://docs.getdbt.com
- https://debezium.io/documentation
