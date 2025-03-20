ARG TIMEZONE="Europe/Moscow"

ARG ASTERISK_VERSION=21.4.1 \
    FREEPBX_VERSION=17.0.19.1

## STAGE DOWNLOAD
FROM busybox AS sources

WORKDIR /app

# Download Asterisk source code
ARG ASTERISK_VERSION
RUN \
# exit immediately if any command exits with a non-zero status
set -e; \
VERSION=${ASTERISK_VERSION}; \
echo "----- Download Asterisk ${VERSION} source code -----"; \
if echo "${VERSION}" | egrep -q ^[0-9]+$; then \
  wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${VERSION}-current.tar.gz; \
else \
  wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${VERSION}.tar.gz; \
fi; \
tar -xf asterisk-*.tar.gz --no-same-owner --no-same-permissions; \
rm asterisk-*.tar.gz; \
[ -d asterisk?* ] && mv asterisk* asterisk; \
echo "----- DONE -----"

# Download FreePBX source code
ARG FREEPBX_VERSION
RUN \
# exit immediately if any command exits with a non-zero status
set -e; \
VERSION=${FREEPBX_VERSION}; \
echo "----- Download FreePBX ${VERSION} source code -----"; \
if echo "${VERSION}" | egrep -q ^[0-9]++$; then \
  wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${VERSION}-latest.tgz; \
else \
  wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-${VERSION}.tgz; \
fi; \
tar -xf freepbx-*.tgz --no-same-owner --no-same-permissions; \
rm freepbx-*.tgz; \
[ -d freepbx?* ] && mv freepbx* freepbx; \
echo "----- DONE -----"

RUN ls -al /app

## STAGE BUILD
# -------------------------------------
FROM ubuntu:24.04 AS build

SHELL [ "/bin/bash", "-c" ]
ENV SHELL="/bin/bash"
ENV PATH=$PATH:/app

# Install prerequisites
RUN \
set -e; \
echo "----- Install prerequisites -----"; \
export DEBIAN_FRONTEND=noninteractive; \
apt-get update; \
apt-get install -y \
  supervisor \
  # MySQL database
  mariadb-server; \
echo "----- DONE -----"

# Create asterisk user and group
RUN \
set -e; \
echo "----- Create asterisk user and group -----"; \
usermod --login asterisk ubuntu; \
groupmod -n asterisk ubuntu; \
echo "----- DONE -----"

COPY --from=sources /app/asterisk /app/asterisk
WORKDIR /app/asterisk

# Install build pre-requirements
RUN \
set -e; \
echo "----- Asterisk: install build pre-requirements -----"; \
./contrib/scripts/install_prereq install; \
./contrib/scripts/get_mp3_source.sh; \
echo "----- DONE -----"

# Prepare for compilation
RUN \
set -e; \
echo "----- Asterisk: prepare for compilation -----"; \
make dist-clean; \
./configure --with-pjproject-bundled; \
make menuselect.makeopts; \
echo "----- DONE -----"

# Configure modules
RUN __MODULES__=( \
# "--disable BUILD_NATIVE" \
"--enable format_mp3" \
"--enable CORE-SOUNDS-EN-WAV" \
"--enable CORE-SOUNDS-RU-WAV" \
"--enable EXTRA-SOUNDS-EN-WAV" \
); \
echo "----- Asterisk: configure modules -----"; \
for MODULE in "${__MODULES__[@]}"; do \
  echo "RUN: menuselect/menuselect ${MODULE}"; \
  menuselect/menuselect ${MODULE} menuselect.makeopts || exit $?; \
done; \
echo "----- Asterisk module and build options -----"; \
menuselect/menuselect --list-options menuselect.makeopts; \
echo "----- DONE -----"

# Build, install and configure
RUN \
set -e; \
echo "----- Asterisk: build and install -----"; \
make install; \
make samples; \
ldconfig; \
echo "----- DONE -----"

# Change permissions
RUN \
set -e; \
echo "----- Asterisk: update permissions -----"; \
chown -R asterisk:asterisk /etc/asterisk; \
chown -R asterisk:asterisk /var/{lib,log,spool,run}/asterisk*; \
echo "----- DONE -----"

COPY --from=sources /app/freepbx /app/freepbx
WORKDIR /app/freepbx

# Install prerequisites
RUN \
set -e; \
echo "----- FreePBX: install prerequisites -----"; \
apt-get install -y \
  # General packates
  cron \
  # Install Apache/PHP/NodeJs packages
  apache2 \
  php \
  php-curl \
  php-zip \
  php-redis \
  php-curl \
  php-cli \
  php-common \
  php-mysql \
  php-gd \
  php-mbstring \
  php-intl \
  php-xml \
  php-bz2 \
  php-ldap \
  php-sqlite3 \
  php-bcmath \
  php-soap \
  php-ssh2 \
  php-fpm \
  nodejs \
  # Required by FreePBX modules
  npm; \
echo "----- DONE -----"

# Prepare Apache server
RUN \
chown -R asterisk:asterisk /var/www/*; \
rm -rf /var/www/html; \
# Prepare environment
sed -i 's/USER=www-data/USER=asterisk/' /etc/apache2/envvars; \
sed -i 's/GROUP=www-data/GROUP=asterisk/' /etc/apache2/envvars; \
sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/*/apache2/php.ini; \
sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf; \
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf; \
# Enable mod_rewrite molule
a2enmod rewrite

# Copy scripts
COPY *.sh /app
RUN chmod +x /app/*.sh

# Install FreePBX
COPY supervisord.*.conf /etc/supervisor/.
RUN \
set -e; \
echo "----- FreePBX: build and install -----"; \
supervisord -c /etc/supervisor/supervisord.default.conf; \
wait_for_ready.sh asterisk mysql; \
./install -n -f || [ $? -eq 1 ]; \
fwconsole moduleadmin refreshsignatures; \
fwconsole moduleadmin downloadinstall backup; \
echo "----- DONE -----"

RUN \
set -e; \
echo "----- FreePBX: update permissions -----"; \
supervisord -c /etc/supervisor/supervisord.mysql.conf; \
wait_for_ready.sh mysql; \
mysql -u root -e "RENAME USER 'freepbxuser'@'localhost' TO 'freepbxuser'@'%';"; \
sed -i 's/\(permit\)=.*/\1=172.0.0.0\/255.0.0.0/' /etc/asterisk/manager.conf; \
cat /etc/asterisk/manager.conf; \
echo "----- DONE -----"

# Cleanup
RUN \
echo "----- Cleanup -----"; \
apt-get autoremove -y; \
apt-get clean; \
rm -rf /{app,tmp}/* /var/lib/apt/lists/*; \
echo "----- DONE -----"


## STAGE SQUASH
# -------------------------------------
FROM scratch
COPY --from=build / /

WORKDIR /app
ENV PATH=$PATH:/app

COPY *.sh .
RUN chmod +x *.sh

COPY supervisord.*.conf /etc/supervisor/.

CMD ["supervisord", "--nodaemon", "-c", "/etc/supervisor/supervisord.default.conf"]
ENTRYPOINT [ "entrypoint.sh" ]
