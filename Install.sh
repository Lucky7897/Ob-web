#!/bin/sh

# Define the URL for the latest release of ob2-web-updater-linux-x64
URL="https://github.com/openbullet/OpenBullet2/releases/latest/download/ob2-web-updater-linux-x64"
DESTINATION="/usr/local/bin/ob2-web-updater"

# Function to check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Function to install .NET SDK and ASP.NET Core Runtime on Alpine
install_dotnet_alpine() {
    echo "Installing .NET SDK and ASP.NET Core Runtime version 8.0 on Alpine..."

    # Install necessary dependencies
    apk add --no-cache \
        icu-libs \
        krb5-libs \
        libgcc \
        libintl \
        libssl1.1 \
        libstdc++ \
        zlib \
        curl \
        bash \
        lttng-ust \
        ca-certificates \
        krb5 \
        libgcc \
        libintl \
        libssl1.1 \
        libstdc++ \
        zlib \
        libgdiplus \
        tzdata \
        ufw

    # Add Microsoft package repository and install .NET SDK
    wget https://packages.microsoft.com/config/alpine/3.14/packages-microsoft-prod.apk -O packages-microsoft-prod.apk
    apk add --allow-untrusted packages-microsoft-prod.apk
    apk update
    apk add --no-cache dotnet-sdk-8.0 aspnetcore-runtime-8.0

    # Clean up
    rm packages-microsoft-prod.apk

    # Verify the installation
    dotnet --list-sdks
    dotnet --list-runtimes

    echo "Installation of .NET SDK and ASP.NET Core Runtime completed."
}

# Function to install ob2-web-updater
install_ob2_web_updater() {
    echo "Downloading the latest ob2-web-updater..."
    curl -L $URL -o $DESTINATION

    # Make the downloaded file executable
    chmod +x $DESTINATION

    # Verify the installation
    if [ -x $DESTINATION ]; then
        echo "Installation of ob2-web-updater successful!"
        echo "You can now run ob2-web-updater using the command: ob2-web-updater"
    else
        echo "Installation of ob2-web-updater failed. Please check the script and try again."
    fi
}

# Function to setup and start the HTTP server with file upload capability
setup_http_server() {
    echo "Creating HTTP server script with upload capability..."
    cat << 'EOF' > http_server_with_upload.py
#!/usr/bin/env python3

import os
import cgi
from http.server import SimpleHTTPRequestHandler, HTTPServer

UPLOAD_PAGE = '''<!DOCTYPE html>
<html>
<body>
   <form enctype="multipart/form-data" method="post">
      <input type="file" name="file">
      <input type="submit" value="Upload">
   </form>
</body>
</html>'''

class SimpleHTTPRequestHandlerWithUpload(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/upload':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(bytes(UPLOAD_PAGE, 'utf-8'))
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == '/upload':
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={'REQUEST_METHOD': 'POST'}
            )
            file_item = form['file']
            if file_item.filename:
                with open(os.path.join('.', file_item.filename), 'wb') as output_file:
                    output_file.write(file_item.file.read())
                self.send_response(200)
                self.end_headers()
                self.wfile.write(bytes('File uploaded successfully', 'utf-8'))
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(bytes('No file uploaded', 'utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(bytes('Not Found', 'utf-8'))

def run(server_class=HTTPServer, handler_class=SimpleHTTPRequestHandlerWithUpload):
    server_address = ('', 8080)
    httpd = server_class(server_address, handler_class)
    print('Starting httpd on port 8080...')
    httpd.serve_forever()

if __name__ == "__main__":
    run()
EOF

    # Make the script executable
    chmod +x http_server_with_upload.py

    # Run the HTTP server
    nohup ./http_server_with_upload.py &
}

# Setup firewall to allow port 8080
setup_firewall() {
    echo "Setting up firewall to allow traffic on port 8080..."
    ufw enable
    ufw allow 8080
    ufw status
}

# Detect the operating system and install the necessary packages
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID

    case $OS in
        alpine)
            install_dotnet_alpine
            ;;
        *)
            echo "Unsupported operating system. Please install .NET SDK and ASP.NET Core Runtime manually."
            exit 1
            ;;
    esac
else
    echo "Unable to detect operating system. Please install .NET SDK and ASP.NET Core Runtime manually."
    exit 1
fi

# Install ob2-web-updater
install_ob2_web_updater

# Run ob2-web-updater
echo "Running ob2-web-updater..."
nohup ob2-web-updater &

# Sleep for a while to allow the process to start
sleep 5

# Check the nohup.out for errors
echo "Checking nohup.out for errors..."
cat nohup.out

# Setup firewall
setup_firewall

# Setup and start the HTTP server
setup_http_server

# Fetch the public IP address
PUBLIC_IP=$(curl -s ifconfig.me)

# Display the link to remotely connect to the tool
echo "You can remotely connect to the HTTP server using the following link:"
echo "http://$PUBLIC_IP:8080"
echo "Upload files at: http://$PUBLIC_IP:8080/upload"
