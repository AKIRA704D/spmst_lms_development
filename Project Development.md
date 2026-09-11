Project Development

Claude Desktop setup - https://claude.com/download

Node.js v24.21.0 LTS winIns(.msi) - https://nodejs.org/en/download



check Node.js installed: cmd -> node -v



configure mcp-server:

* cmd -> npm config set strict-ssl false -> npm install -g postgres-mysql-mcp-server
* MySQL -> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql\_native\_password BY '5K541'; -> FLUSH PRIVILEGES;



Configure Claude: settings -> developer -> edit config (open claude\_desktop\_config.json)

NuGet Installations:

MySQL.Data v26.7.0 - MySQL connection

Crypt.Net-Next v4.2.0

