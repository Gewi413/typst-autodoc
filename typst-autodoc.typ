/**
 * splits and filters the file into function headers with magic \/\*\*\
 * @param text the text which is to get parsed
 * @returns List of all functions with a docstring as plaintext
 */
#let findDocs(text) = {
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
      if ")" in line {
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
#let error(message: "error") = box(fill: red, inset: 5pt, [#message])

/**
 * parses a docstring and functionhead into a dictonary
 * @returns dictionary with keys name, params, see-also, description, errors, version
 */
#let parseDocs(text) = {
  let info = (
    name: "",
    params:(:),
    see-also: (),
    description: "",
    errors: (),
    version: "",
    returns: "",
  )
  
  let lines = text.split("\n")
  let head = lines.at(-1)
  let name = if ")" in head {
    head.matches(regex("let ([^(]+)"))
  } else {
    head.matches(regex("let ([^ ]+)"))
  }.at(0).captures.at(0)
  info.name = name

  let params = (:)
  for line in lines.slice(0,-1) {
    let line = line.trim(regex("[ */]"))
    let onward = line.split(" ").slice(1,)
    let firstArg = onward.at(0, default: "")
    
    if "@" not in line {
      info.description += line + "\n"
    } else if line.starts-with("@param") {
      if onward.len() > 1 {
        params.insert(firstArg, onward.slice(1,).join(" "))
      }
    } else if line.starts-with("@returns") {
      info.returns = onward.join(" ")
    } else if line.starts-with("@see") {
      info.see-also += (firstArg,)
    } else if line.starts-with("@version") {
        info.insert("version", onward.join(" "))
    } else  {
      info.errors += (line.split(" ").at(0),)
    }
  }
  let args = head.slice(head.position("(") + 1, head.position(")")).split(",")
  if args != () {
    for arg in args {
      let name = arg.split(":").at(0).trim()
      info.params.insert(name, (:))
      let default = arg.split(":").at(1, default: none)
      if default != none {
        info.params.at(name).default = default.trim()
      }
      if name in params {
        info.params.at(name).description = params.at(name)
      }
    }
  }
  info.description = info.description.trim()
  return info
}

/**
 * prints the documentation
 * == Feature
 * can include _inline_ typst for more (rocket-emoji)
 * @version 0.1.1
 * @param file The file to parse into a documentation
 * @returns Content filled with blocks for each function
 * @see parseDocs
 */
#let main(file) = {
  show heading.where(level: 2): set text(fill: gray, size: 11pt)
  set text(font: "Fira Sans")
  let headers = findDocs(read(file))
  for function in headers {
    block(breakable: false, box(fill: gray.lighten(80%), width: 100%, inset: 5pt, {
      let info = parseDocs(function)
      [= #info.name #label(info.name)
        #if info.version != "" [
          #h(2em) Version: #info.version
          
        ]
        #eval("[" + info.description + " ]")
        #if info.params != (:) [
          == Parameters
          #for (name, param) in info.params [
            / #raw(name): #param.at("description", default: "") #if "default" in param [
              (default value: #raw(param.default))
            ]
          ]
        ]
        #if info.returns != "" [
          == Return value
          #info.returns
        ]
        
        #if info.see-also != () {
          [== See also]
          for other in info.see-also [
            - #link(label(other), other)
          ]
        }
        #if info.errors != () {
          [== Parsing errors]
          for e in info.errors {
            error(message: e)
          }
        }
      ]
    }))
  }
}
