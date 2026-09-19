Project Development

Claude Desktop setup - https://claude.com/download

Node.js v24.21.0 LTS winIns(.msi) - https://nodejs.org/en/download



check Node.js installed: cmd -> node -v



configure mcp-server:

MySQL Database Access:

* cmd -> npm config set strict-ssl false -> npm install -g postgres-mysql-mcp-server
* MySQL -> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql\_native\_password BY '5K541'; -> FLUSH PRIVILEGES;



GitHub Access:

cmd -> npm install -g @modelcontextprotocol/server-github

Token: ghp\_qEUK4DFevQ8G8BmUubVHo59oM49Osf04Y6x6



Configure Claude: settings -> developer -> edit config (open claude\_desktop\_config.json)



NuGet Installations:

MySQL.Data v26.7.0 - MySQL connection

Crypt.Net-Next v4.2.0

OpenXML v3.5.1

ClosedXML v0.105.1

CsvHelper v33.1.0

