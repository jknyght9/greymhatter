# Importing a timeline into Timesketch

1. Your timeline must be in /opt/share/plaso! This directory is mapped to the container you will be using.
2. If Timesketch has been restarted, you will need to reinstall the importer
   ```shell
   cd /opt/timesketch/
   sudo docker compose exec timesketch-worker bash -c "pip3 install timesketch-import-client"
   ```
3. Get a list of sketches from Timesketch
   ```shell
   cd /opt/timesketch/
   sudo docker compose exec tsctl list-sketches
   ```
4. Import the timeline from the plaso directory
   ```shell
   cd /opt/timesketch/
   sudo docker compose exec timesketch-worker timesketch_importer --sketch_id <ID> --timeline_name <NAME> /share/plaso/HOSTNAME.plaso
   ```
