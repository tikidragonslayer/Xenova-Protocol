
        <!DOCTYPE html>
        <html lang="en">
          <head><script>window.localserviceSettings = {"forwardPreviewErrors":true};</script><script src="/.localservice@runtime.34c588ed.js"></script>
            <meta charset="UTF-8" />
            <title>Error</title>
            <script type="module">
              const error = {"message":"Failed to resolve import \"@nomicfoundation/hardhat-toolbox\" from \"hardhat.config.ts\". Does the file exist?","stack":"    at TransformPluginContext._formatError (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49304:41)\n    at TransformPluginContext.error (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49299:16)\n    at normalizeUrl (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64090:23)\n    at async eval (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64222:39)\n    at async TransformPluginContext.transform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64149:7)\n    at async PluginContainer.transform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49145:18)\n    at async loadAndTransform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:51978:27)","id":"/home/project/hardhat.config.ts","frame":"1  |  import \"@nomicfoundation/hardhat-toolbox\";\n   |          ^\n2  |  import \"@openzeppelin/hardhat-upgrades\";\n3  |  import * as dotenv from \"dotenv\";","plugin":"vite:import-analysis","pluginCode":"import \"@nomicfoundation/hardhat-toolbox\";\nimport \"@openzeppelin/hardhat-upgrades\";\nimport * as dotenv from \"dotenv\";\ndotenv.config();\nconst config = {\n  solidity: {\n    version: \"0.8.19\",\n    settings: {\n      optimizer: {\n        enabled: true,\n        runs: 200\n      }\n    }\n  },\n  networks: {\n    // Mainnets\n    ethereum: {\n      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    bsc: {\n      url: \"https://bsc-dataseed.binance.org\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    polygon: {\n      url: \"https://polygon-rpc.com\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    arbitrum: {\n      url: \"https://arb1.arbitrum.io/rpc\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    optimism: {\n      url: \"https://mainnet.optimism.io\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    fantom: {\n      url: \"https://rpc.ftm.tools\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    },\n    avalanche: {\n      url: \"https://api.avax.network/ext/bc/C/rpc\",\n      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []\n    }\n  },\n  etherscan: {\n    apiKey: {\n      mainnet: process.env.ETHERSCAN_API_KEY || \"\",\n      bsc: process.env.BSCSCAN_API_KEY || \"\",\n      polygon: process.env.POLYGONSCAN_API_KEY || \"\",\n      arbitrum: process.env.ARBISCAN_API_KEY || \"\",\n      optimism: process.env.OPTIMISM_API_KEY || \"\",\n      fantom: process.env.FTMSCAN_API_KEY || \"\",\n      avalanche: process.env.SNOWTRACE_API_KEY || \"\"\n    }\n  }\n};\n","loc":{"file":"/home/project/hardhat.config.ts","line":2,"column":7}}
              try {
                const { ErrorOverlay } = await import("/@vite/client")
                document.body.appendChild(new ErrorOverlay(error))
              } catch {
                const h = (tag, text) => {
                  const el = document.createElement(tag)
                  el.textContent = text
                  return el
                }
                document.body.appendChild(h('h1', 'Internal Server Error'))
                document.body.appendChild(h('h2', error.message))
                document.body.appendChild(h('pre', error.stack))
                document.body.appendChild(h('p', '(Error overlay failed to load)'))
              }
            </script>
          </head>
          <body>
          </body>
        </html>
      