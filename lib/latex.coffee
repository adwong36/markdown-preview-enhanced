PDF = null
{spawn} = require 'child_process'
path = require 'path'
fs = require 'fs'

cleanUpFiles = (directoryPath, filePrefix)->
  fs.readdir directoryPath, (error, items)->
    return if error

    items.forEach (fileName)->
      if fileName.startsWith(filePrefix) and !fileName.match(/\.(la)?tex/)
        fs.unlink path.resolve(directoryPath, fileName)

###
# @param svgDirectoryPath: where the svg files should be saved.
#        If not provided, then the svg files will be stored in temp dir.
# @param markdownDirectoryPath: where your markdown file is located.
# callback (error, svgMarkdown)
###
toSVGMarkdown = (texFilePath, {latexEngine, latexGraph, svgDirectoryPath, markdownDirectoryPath}, callback)->
  latexEngine ?= 'pdflatex'

  task = spawn latexEngine, [texFilePath], {cwd: path.dirname(texFilePath)}

  chunks = []
  task.stdout.on 'data', (chunk)->
    chunks.push(chunk)

  errorChunks = []
  task.stderr.on 'data', (chunk)->
    errorChunks.push(chunk)

  task.on 'close', ()->
    if errorChunks.length
      return callback(Buffer.concat(errorChunks).toString(), null)
    else
      output = Buffer.concat(chunks).toString()
      if output.indexOf('LaTeX Error') >= 0 # meet error
        return callback(output, null)

      pdfFilePath = texFilePath.replace(/\.(la)?tex$/, '.pdf')

      PDF ?= require('./pdf')
      PDF.toSVGMarkdown pdfFilePath, {svgDirectoryPath, markdownDirectoryPath}, (error, svgMarkdown)->
        if !error
          cleanUpFiles path.dirname(pdfFilePath), path.basename(pdfFilePath).replace(/\.pdf$/, '')

        return callback(error, svgMarkdown)

  task.stdin.end()

module.exports = LaTeX = {toSVGMarkdown}