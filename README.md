# dwh-hw2 komarov
В таблицах и в хранилище в целом присутствует некая нелогичность, 
но я все делал так, чтобы соответствовать схеме из pdf.

Контейнеры:
- `postgres_master` - мастер-база
- `postgres_slave` - ее реплика (в композ закомментил, 
чтоб не мешалась, в задании она не участвует)
- `vertica-dwh` - потребует логин, сам собрал образ, 
чтоб она не инитилась базой, положил докерфайл, как
собирал
- `zookeeper` 
- `broker`
- `debezium`
- `debezium-ui`
- `schema-registry`
- `rest-proxy` - по этим все понятно
- `connector` - дебиановский контейнер, пробрасывает 
коннекторы для кафка.

Собираем командой
```shell

```


#### Источники вдохновения:
- https://habr.com/ru/companies/avito/articles/322510/
- https://www.anchormodeling.com/tutorials/
- https://habr.com/ru/companies/sberbank/articles/414895/
- https://ivan-shamaev.ru/dbt-clickhouse-tutorial-run-model-data/
- https://docs.getdbt.com
- https://debezium.io/documentation