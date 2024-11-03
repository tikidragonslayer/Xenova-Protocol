
        <!DOCTYPE html>
        <html lang="en">
          <head><script>window.localserviceSettings = {"forwardPreviewErrors":true};</script><script src="/.localservice@runtime.34c588ed.js"></script>
            <meta charset="UTF-8" />
            <title>Error</title>
            <script type="module">
              const error = {"message":"Failed to resolve import \"@openzeppelin/test-environment\" from \"test/XenovaCore.test.js\". Does the file exist?","stack":"    at TransformPluginContext._formatError (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49304:41)\n    at TransformPluginContext.error (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49299:16)\n    at normalizeUrl (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64090:23)\n    at async eval (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64222:39)\n    at async TransformPluginContext.transform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:64149:7)\n    at async PluginContainer.transform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:49145:18)\n    at async loadAndTransform (file:///home/project/node_modules/vite/dist/node/chunks/dep-BWSbWtLw.js:51978:27)","id":"/home/project/test/XenovaCore.test.js","frame":"1  |  import { accounts, contract } from '@openzeppelin/test-environment';\n   |                                      ^\n2  |  import { BN, expectEvent, expectRevert, time } from '@openzeppelin/test-helpers';\n3  |  import { expect } from 'chai';","plugin":"vite:import-analysis","pluginCode":"import { accounts, contract } from '@openzeppelin/test-environment';\nimport { BN, expectEvent, expectRevert, time } from '@openzeppelin/test-helpers';\nimport { expect } from 'chai';\n\nconst XenovaCore = contract.fromArtifact('XenovaCore');\n\ndescribe('XenovaCore', function() {\n  const [owner, user1, user2] = accounts;\n  \n  beforeEach(async function() {\n    this.xenova = await XenovaCore.new({ from: owner });\n  });\n\n  describe('Initialization', function() {\n    it('should initialize with correct parameters', async function() {\n      const totalSupply = await this.xenova.TOTAL_SUPPLY();\n      expect(totalSupply).to.be.bignumber.equal(new BN('50000'));\n\n      const stakersShare = await this.xenova.STAKERS_SHARE();\n      expect(stakersShare).to.be.bignumber.equal(new BN('80'));\n\n      const lpShare = await this.xenova.LP_SHARE();\n      expect(lpShare).to.be.bignumber.equal(new BN('20'));\n    });\n\n    it('should not allow double initialization', async function() {\n      await this.xenova.initialize({ from: owner });\n      await expectRevert(\n        this.xenova.initialize({ from: owner }),\n        'Already initialized'\n      );\n    });\n  });\n\n  describe('Control renouncement', function() {\n    it('should allow renouncing control after initialization', async function() {\n      await this.xenova.initialize({ from: owner });\n      const tx = await this.xenova.renounceControl({ from: owner });\n      expectEvent(tx, 'ControlRenounced');\n    });\n\n    it('should not allow renouncing before initialization', async function() {\n      await expectRevert(\n        this.xenova.renounceControl({ from: owner }),\n        'Not initialized'\n      );\n    });\n  });\n\n  describe('Parameter verification', function() {\n    it('should verify total supply calculation', async function() {\n      const isValid = await this.xenova._verifyProtocolParameters();\n      expect(isValid).to.be.true;\n    });\n  });\n});","loc":{"file":"/home/project/test/XenovaCore.test.js","line":1,"column":37}}
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
      