local band = assert(bit.band)
local bor = assert(bit.bor)
local bnot = assert(bit.bnot)
local bxor = assert(bit.bxor)
local cos = assert(math.cos)
local floor = assert(math.floor)
local insert = assert(table.insert)
local lshift = assert(bit.lshift)
local max = assert(math.max)
local min = assert(math.min)
local pi = assert(math.pi)
local random = assert(love.math.random)
local remove = assert(table.remove)
local rshift = assert(bit.rshift)
local sin = assert(math.sin)
local sqrt = assert(assert(math.sqrt))

local brushes = {
  "circle",
  "square",
  "triangle",
  "ascii",
}

local strokeSizes = {
  ascii = 6,
  circle = 5,
  square = 6,
  triangle = 12,
}

function find(t, v)
  for k, v2 in pairs(t) do
    if v2 == v then
      return k
    end
  end

  return nil
end

function shuffle(t)
  for i = 1, #t - 1 do
    local j = random(i, #t)
    t[i], t[j] = t[j], t[i]
  end
end

function clamp(x, x1, x2)
  return min(max(x, x1), x2)
end

function unpackHalfBytes(byte)
  local upperHalf = rshift(band(byte, 0xf0), 4)
  local lowerHalf = band(byte, 0xf)

  return upperHalf, lowerHalf
end

function packHalfBytes(upperHalf, lowerHalf)
  upperHalf = band(upperHalf, 0xf)
  lowerHalf = band(lowerHalf, 0xf)

  return bor(lshift(upperHalf, 4), lowerHalf)
end

function readPainting(file)
  local painting = {
    strokes = {},
  }

  -- Magic
  local magic = file:read(4)
  assert(magic == "LIMA", "Invalid file magic")

  -- Version
  local version = love.data.unpack("B", file:read(1))
  assert(version == 1, "Unsupported file version")

  -- Brush
  local brushIndex = love.data.unpack("B", file:read(1))
  painting.brush = assert(brushes[brushIndex], "Invalid brush index")

  -- Stroke count
  local strokeCountUpper, strokeCountLower = love.data.unpack("BB", file:read(2))
  local strokeCount = 256 * strokeCountUpper + strokeCountLower

  -- Strokes

  local strokeSize = assert(strokeSizes[painting.brush])
  local strokeFormat = string.rep("B", strokeSize)

  for i = 1, strokeCount do
    painting.strokes[i] = {love.data.unpack(strokeFormat, file:read(#strokeFormat))}
  end

  return painting
end

function writePainting(painting, file)
  file:write("LIMA") -- Magic
  file:write(love.data.pack("string", "B", 1)) -- Version

  -- Brush
  local brushIndex = assert(find(brushes, painting.brush))
  file:write(love.data.pack("string", "B", brushIndex))

  -- Stroke count

  local strokeCount = #painting.strokes

  local strokeCountUpper = rshift(band(strokeCount, 0xff00), 8)
  local strokeCountLower = band(strokeCount, 0xff)

  file:write(love.data.pack("string", "BB", strokeCountUpper, strokeCountLower))

  -- Strokes

  local strokeSize = assert(strokeSizes[painting.brush])
  local strokeFormat = string.rep("B", strokeSize)

  for i = 1, strokeCount do
    file:write(love.data.pack("string", strokeFormat, unpack(painting.strokes[i])))
  end
end

function loadPainting(filename)
  local file = assert(io.open(filename, "rb"))
  local success, result = pcall(readPainting, file)
  file:close()
  assert(success, result)
  return result
end

function savePainting(painting, filename)
  local file = io.open(filename, "wb")
  local success, result = pcall(writePainting, painting, file)
  file:close()
  assert(success, result)
end

function clonePainting(painting)
  local strokes = {}

  for i, stroke in ipairs(painting.strokes) do
    strokes[i] = {unpack(stroke)}
  end

  return {
    brush = painting.brush,
    strokes = strokes,
  }
end

function generateBoolean()
  return random(0, 1) == 1
end

function generateByte()
  return random(0, 255)
end

function generateStroke(brush)
  if brush == "triangle" then
    local x = random()
    local y = random()

    local angle1 = 2 * pi * random()
    local angle2 = angle1 + 2 * pi / 3
    local angle3 = angle1 + 4 * pi / 3

    local radius = 0.5 * random() ^ 2

    local x1 = x + radius * cos(angle1)
    local y1 = y + radius * sin(angle1)

    local x2 = x + radius * cos(angle2)
    local y2 = y + radius * sin(angle2)

    local x3 = x + radius * cos(angle3)
    local y3 = y + radius * sin(angle3)

    x1 = clamp(floor(0.5 * (x1 + 0.5) * 256), 0, 255)
    y1 = clamp(floor(0.5 * (y1 + 0.5) * 256), 0, 255)

    x2 = clamp(floor(0.5 * (x2 + 0.5) * 256), 0, 255)
    y2 = clamp(floor(0.5 * (y2 + 0.5) * 256), 0, 255)

    x3 = clamp(floor(0.5 * (x3 + 0.5) * 256), 0, 255)
    y3 = clamp(floor(0.5 * (y3 + 0.5) * 256), 0, 255)

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {
      x1, y1, redGreen, blueAlpha,
      x2, y2, redGreen, blueAlpha,
      x3, y3, redGreen, blueAlpha,
    }
  else
    local stroke = {}

    for i = 1, strokeSizes[brush] do
      stroke[i] = generateByte()
    end

    return stroke
  end
end

function generatePainting(brush, size)
  local strokes = {}

  for i = 1, size do
    strokes[i] = generateStroke(brush)
  end

  return {
    brush = brush,
    strokes = strokes,
  }
end

function mutateStroke(stroke)
  local i = random(1, #stroke)

  if generateBoolean() then
    stroke[i] = generateByte()
  else
    local upperHalf, lowerHalf = unpackHalfBytes(stroke[i])

    if generateBoolean() then
      upperHalf = generateByte()
    else
      lowerHalf = generateByte()
    end

    stroke[i] = packHalfBytes(upperHalf, lowerHalf)
  end
end

function mutatePainting(painting)
  local strokes = painting.strokes

  if generateBoolean() then
    local i = random(1, #strokes)
    mutateStroke(strokes[i])
  else
    if generateBoolean() then
      local i = random(1, #strokes)
      local j = random(1, #strokes)

      local stroke = remove(strokes, i)
      insert(strokes, j, stroke)
    else
      local i = random(1, #strokes)
      local j = random(1, #strokes)

      remove(strokes, i)
      local stroke = generateStroke(painting.brush)

      if generateBoolean() then
        j = #strokes
      end

      insert(strokes, j, stroke)
    end
  end
end

local function drawPaintingToCanvas(painting, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")

  local canvasWidth, canvasHeight = canvas:getDimensions()
  local canvasSize = sqrt(canvasWidth * canvasHeight)

  if painting.brush == "circle" then
    for i, stroke in ipairs(painting.strokes) do
      local x, y, size, redGreen, blueAlpha = unpack(stroke)

      local red, green = unpackHalfBytes(redGreen)
      local blue, alpha = unpackHalfBytes(blueAlpha)

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)

      love.graphics.circle(
        "fill",
        x / 255 * canvasWidth,
        y / 255 * canvasHeight,
        0.5 * (size / 255) ^ 2 * canvasSize)
    end
  elseif painting.brush == "square" then
    for i, stroke in ipairs(painting.strokes) do
      local x, y, angle, size, redGreen, blueAlpha = unpack(stroke)

      local red, green = unpackHalfBytes(redGreen)
      local blue, alpha = unpackHalfBytes(blueAlpha)

      local halfSize = 0.5 * (size / 255) ^ 2 * canvasSize

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)

      love.graphics.push()

      love.graphics.translate(x / 255 * canvasWidth, y / 255 * canvasHeight)
      love.graphics.rotate(2 * pi * angle / 256)

      love.graphics.polygon(
        "fill",
        -halfSize, -halfSize,
        halfSize, -halfSize,
        halfSize, halfSize,
        -halfSize, halfSize)

      love.graphics.pop()
    end
  elseif painting.brush == "triangle" then
    local vertices = {}

    for i, stroke in ipairs(painting.strokes) do
      local x1, y1, redGreen1, blueAlpha1,
        x2, y2, redGreen2, blueAlpha2,
        x3, y3, redGreen3, blueAlpha3 = unpack(stroke)

      x1 = (2 * x1 / 255 - 0.5) * canvasWidth
      y1 = (2 * y1 / 255 - 0.5) * canvasHeight

      x2 = (2 * x2 / 255 - 0.5) * canvasWidth
      y2 = (2 * y2 / 255 - 0.5) * canvasHeight

      x3 = (2 * x3 / 255 - 0.5) * canvasWidth
      y3 = (2 * y3 / 255 - 0.5) * canvasHeight

      local red1, green1 = unpackHalfBytes(redGreen1)
      local blue1, alpha1 = unpackHalfBytes(blueAlpha1)

      local red2, green2 = unpackHalfBytes(redGreen2)
      local blue2, alpha2 = unpackHalfBytes(blueAlpha2)

      local red3, green3 = unpackHalfBytes(redGreen3)
      local blue3, alpha3 = unpackHalfBytes(blueAlpha3)

      insert(
        vertices,
        {x1, y1, 0, 0, red1 / 15, green1 / 15, blue1 / 15, alpha1 / 15})

      insert(
        vertices,
        {x2, y2, 0, 0, red2 / 15, green2 / 15, blue2 / 15, alpha2 / 15})

      insert(
        vertices,
        {x3, y3, 0, 0, red3 / 15, green3 / 15, blue3 / 15, alpha3 / 15})
    end

    triangleMesh:setVertices(vertices)
    love.graphics.draw(triangleMesh)
  elseif painting.brush == "ascii" then
    for i, stroke in ipairs(painting.strokes) do
      local character, x, y, angleSize, redGreen, blueAlpha = unpack(stroke)

      if character >= 32 and character <= 126 then
        character = string.char(character)
        local angle, size = unpackHalfBytes(angleSize)

        local red, green = unpackHalfBytes(redGreen)
        local blue, alpha = unpackHalfBytes(blueAlpha)

        local font = fonts[size]

        if font then
          love.graphics.setFont(font)

          local characterWidth = font:getWidth(character)
          local characterHeight = font:getHeight()

          love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)

          love.graphics.print(
            character, canvasWidth * x / 255,
            canvasHeight * y / 255,
            2 * pi * angle / 16,
            1,
            1,
            0.5 * characterWidth,
            0.5 * characterHeight)
        end
      end
    end
  else
    assert(false)
  end

  love.graphics.setCanvas()
end

local function getFitness(image1, image2, fitnessCanvas)
  love.graphics.push("all")
  love.graphics.setShader(fitnessShader)
  fitnessShader:send("referenceImage", image2)
  love.graphics.setCanvas(fitnessCanvas)
  love.graphics.setBlendMode("replace", "premultiplied")
  love.graphics.draw(image1)
  love.graphics.setCanvas()
  love.graphics.setShader()
  love.graphics.pop()

  local data = fitnessCanvas:newImageData(1, 10, 0, 0, 1, 1)
  local r, g, b, a = data:getPixel(0, 0)
  data:release()
  return sqrt(0.25 * (r + g + b + a))
end

function love.load(arg)
  love.filesystem.setIdentity("lima")

  if #arg ~= 3 or (arg[1] ~= "evolve" and arg[1] ~= "rasterize") then
    print("Usage: love . evolve <source> <target>")
    print("       love . rasterize <source> <target>")
    love.event.quit(1)
    return
  end

  _, sourceFilename, targetFilename = unpack(arg)

  print("Loading imitation...")
  local success, result = pcall(loadPainting, targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generatePainting("triangle", 256)
  end

  print("Loading reference...")
  referenceImage = love.graphics.newImage(sourceFilename)

  triangleMesh = love.graphics.newMesh(3 * #parent.strokes, "triangles")
  fonts = {}

  for size = 1, 15 do
    fonts[size] = love.graphics.newFont(512 * size / 15)
  end

  canvas = love.graphics.newCanvas(512, 512, {msaa = 4})

  fitnessCanvas = love.graphics.newCanvas(512, 512, {
    format = "rgba32f",
    mipmaps = "auto",
  })

  local fitnessPixelCode = [[
    uniform Image referenceImage;

    vec4 effect(vec4 color, Image imitationImage, vec2 textureCoords, vec2 screenCoords)
    {
      vec4 imitationColor = Texel(imitationImage, textureCoords);
      vec4 referenceColor = Texel(referenceImage, textureCoords);
      vec4 fitnessColor = referenceColor - imitationColor;
      return fitnessColor * fitnessColor;
    }
  ]]

  fitnessShader = love.graphics.newShader(fitnessPixelCode)

  drawPaintingToCanvas(parent, canvas)
  parentFitness = getFitness(canvas, referenceImage, fitnessCanvas)

  local parentImageData = canvas:newImageData()
  parentImage = love.graphics.newImage(parentImageData)
  parentImageData:release()

  print("Fitness: " .. parentFitness)
end

function love.update(dt)
  local child = clonePainting(parent)
  mutatePainting(child)

  drawPaintingToCanvas(child, canvas)
  local childFitness = getFitness(canvas, referenceImage, fitnessCanvas)

  if childFitness < parentFitness then
    parent = child
    parentFitness = childFitness

    local parentImageData = canvas:newImageData()
    parentImage:release()
    parentImage = love.graphics.newImage(parentImageData)
    parentImageData:release()

    print("Fitness: " .. parentFitness)
    savePainting(parent, targetFilename)
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(referenceImage, 0, 0)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(parentImage, 512, 0)
  love.graphics.setBlendMode("alpha")

  local em = love.graphics.getFont():getWidth("M")
  love.graphics.print("FPS: " .. love.timer.getFPS(), em, em)
end

function love.quit()
  if parent and targetFilename then
    print("Saving...")
    savePainting(parent, targetFilename)
  end
end

function love.keypressed(key, scancode, isrepeat)
  if key == "return" then
    local filename = "screenshot-" .. os.time() .. ".png"
    love.graphics.captureScreenshot(filename)
    local directory = love.filesystem.getSaveDirectory()
    print("Saved screenshot: " .. directory .. "/" .. filename)
  end
end
