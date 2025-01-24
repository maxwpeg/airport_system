FROM vertica/vertica-ce:latest
RUN sed -i '/VMART_ETL_SCRIPT/d' /home/dbadmin/docker-entrypoint.sh