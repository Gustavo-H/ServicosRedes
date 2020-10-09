#!/bin/bash

ufw --force reset

ufw default deny incoming

ufw default allow outgoing

ufw allow 22/tcp

ufw allow 80/tcp

ufw allow 443/tcp

ufw allow 1883/tcp

ufw allow 3306/tcp

ufw enable

