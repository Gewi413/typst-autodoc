/**
 * splits and filters the file into function headers with magic \/\*\*\
 * @param text the text which is to get parsed
 */
#let parseHeaders(text) = {
  let docComment = false
  let function = false
  let buff = ""
  let headers = ()
  for line in text.split("\n") {
    if line.starts-with("/**") {
      buff = ""
      docComment = true
    }
    if docComment {
      buff += line + "\n"
      if "*/" in line {
        docComment = false
        function = true
      }
    }
    if function {
      buff += line + " "
      if "=" in line {
        headers.push(buff)
        buff = ""
        function = false
      }
    }
  }
  return headers
}

/**
 * makes a red error box
 * @param message the message to error with
 * @foo
 */
#let error(message) = box(fill: red, inset: 5pt, [#message])

/**
 * prints the documentation
 * == Feature
 * can include _inline_ typst for more (rocket-emoji)
 * @param file The file to parse into a documentation
 * @version 0.1.0
 * @returns Content filled with blocks for each function
 * @see parseHeaders
 */
#let main(file) = {
  show heading.where(level: 2): set text(fill: gray, size: 11pt)
  set text(font: "Fira Sans")
  let headers = parseHeaders(read(file))
  for function in headers {
    block(breakable: false, box(fill: gray.lighten(80%), width: 100%, inset: 5pt, {
      let lines = function.split("\n")
      let head = lines.at(-1)
      let name = if ")" in head {
        head.matches(regex("let ([^(]+)"))
      } else {
        head.matches(regex("let ([^ ]+)"))
      }.at(0).captures.at(0)
      [= #name #label(name)]
      
      let info = ("params":(:),"see-also": [== See also])
      let buff = ""
      for line in lines.slice(0,-1) {
        let line = line.trim(regex("[ */]"))
        let onward = line.split(" ").slice(1,)
        let firstArg = onward.at(0, default: "")
        
        if "@" not in line {
          buff += line + "\n"
        } else if line.starts-with("@param") {
          if onward.len() > 1 {
            info.at("params").insert(firstArg, onward.slice(1,).join(" "))
          }
        } else if line.starts-with("@returns") {
          info.insert("returns", onward.join(" "))
        } else if line.starts-with("@see") {
          info.at("see-also") += link(label(firstArg))[- #firstArg]
        } else if line.starts-with("@version") {
            info.insert("version", onward.join(" "))
        } else  {
          [#error("unknown: " + line.split(" ").at(0))\ ]
        }
      }
      if "version" in info [
        #h(2em) Version: #info.at("version")
        
      ]
      eval("[" + buff + "]")
      if ")" in head {
        let args = head.slice(head.position("(") + 1, head.position(")")).split(",")
        if args != () {
          let params = info.at("params")
          [== Parameters]
          for arg in args {
            if arg.split(":").at(0).trim() in params {
              [/ #raw(arg.trim()): #params.at(arg.split(":").at(0).trim())]
            } else {
              [/ #raw(arg.trim()):]
            }
          }
        }
        if "returns" in info [
          == Return value
          #info.at("returns")
        ]
      } else {
        [== Value
        #raw(head.split("=").at(1).trim())
        ]
      }
      if info.at("see-also") != [== See also] {
        [#info.at("see-also")]
      }
    }))
  }
}

