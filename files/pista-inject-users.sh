#!/bin/bash
PGPASSWORD=o2s psql -v ON_ERROR_STOP=1 -U o2s -h localhost -f /volume/config/clients/passwd.pista.sql
