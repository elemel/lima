local band = bit.band
local bor = bit.bor
local cos = math.cos
local floor = math.floor
local lshift = bit.lshift
local pi = math.pi
local random = love.math.random
local rshift = bit.rshift
local sin = math.sin
local sqrt = math.sqrt

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

function loadPainting(filename)
  local success, result = pcall(dofile, targetFilename)
  return success, result
end

function savePainting(painting, filename)
  local file = io.open(filename, "w")
  file:write("return {\n")
  file:write("  brush = \"" .. painting.brush .. "\",\n")
  file:write("\n")
  file:write("  strokes = {\n")

  for i, stroke in ipairs(painting.strokes) do
    file:write("    {" .. table.concat(stroke, ", ") .. "},\n")
  end

  file:write("  },\n")
  file:write("}\n")
  file:close()
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

function generateSize()
  local size = lshift(1, random(0, 7))
  local mask = size - 1
  local jitter = band(generateByte(), mask)
  return bor(size, jitter)
end

function generateHalfSize()
  local size = lshift(1, random(0, 3))
  local mask = size - 1
  local jitter = band(generateByte(), mask)
  return bor(size, jitter)
end

function generateStroke(brush)
  if brush == "circle" then
    local x = generateByte()
    local y = generateByte()

    local size = generateSize()

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {x, y, size, redGreen, blueAlpha}
  elseif brush == "square" then
    local x = generateByte()
    local y = generateByte()

    local angle = generateByte()
    local size = generateSize()

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {x, y, angle, size, redGreen, blueAlpha}
  elseif brush == "shadedTriangle" then
    local x = random()
    local y = random()

    local angle1 = 2 * pi * random()
    local angle2 = angle1 + 2 * pi / 3
    local angle3 = angle1 + 4 * pi / 3

    local radius = 0.5 * generateSize() / 255

    local x1 = x + radius * cos(angle1)
    local y1 = y + radius * sin(angle1)

    local x2 = x + radius * cos(angle2)
    local y2 = y + radius * sin(angle2)

    local x3 = x + radius * cos(angle3)
    local y3 = y + radius * sin(angle3)

    x1 = floor(0.5 * (x1 + 0.5) * 256)
    y1 = floor(0.5 * (y1 + 0.5) * 256)

    x2 = floor(0.5 * (x2 + 0.5) * 256)
    y2 = floor(0.5 * (y2 + 0.5) * 256)

    x3 = floor(0.5 * (x3 + 0.5) * 256)
    y3 = floor(0.5 * (y3 + 0.5) * 256)

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {
      x1, y1, redGreen, blueAlpha,
      x2, y2, redGreen, blueAlpha,
      x3, y3, redGreen, blueAlpha,
    }
  elseif brush == "ascii" then
    local character = generateByte()

    local x = generateByte()
    local y = generateByte()

    local angleSize = generateByte()

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {character, x, y, angleSize, redGreen, blueAlpha}
  elseif brush == "triangle" then
    local x = random()
    local y = random()

    local angle1 = 2 * pi * random()
    local angle2 = angle1 + 2 * pi / 3
    local angle3 = angle1 + 4 * pi / 3

    local radius = 0.5 * generateSize() / 255

    local x1 = x + radius * cos(angle1)
    local y1 = y + radius * sin(angle1)

    local x2 = x + radius * cos(angle2)
    local y2 = y + radius * sin(angle2)

    local x3 = x + radius * cos(angle3)
    local y3 = y + radius * sin(angle3)

    x1 = floor(0.5 * (x1 + 0.5) * 256)
    y1 = floor(0.5 * (y1 + 0.5) * 256)

    x2 = floor(0.5 * (x2 + 0.5) * 256)
    y2 = floor(0.5 * (y2 + 0.5) * 256)

    x3 = floor(0.5 * (x3 + 0.5) * 256)
    y3 = floor(0.5 * (y3 + 0.5) * 256)

    local redGreen = generateByte()
    local blueAlpha = generateByte()

    return {x1, y1, x2, y2, x3, y3, redGreen, blueAlpha}
  else
    assert(false)
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

function moveStroke(painting)
  local i = random(1, #painting.strokes)
  local j = random(1, #painting.strokes)

  local stroke = table.remove(painting.strokes, i)
  table.insert(painting.strokes, j, stroke)
end

function replaceStroke(painting)
  local i = random(1, #painting.strokes)
  local j = random(1, #painting.strokes)

  local stroke = generateStroke(painting.brush)

  table.remove(painting.strokes, i)
  table.insert(painting.strokes, j, stroke)
end

function mutatePosition(x, y)
  local size = generateSize()

  x = band(x + random(-size, size), 0xff)
  y = band(y + random(-size, size), 0xff)

  return x, y
end

function mutateHalfColor(redGreen, blueAlpha)
  local red, green = unpackHalfBytes(redGreen)
  local blue, alpha = unpackHalfBytes(blueAlpha)

  local size = generateHalfSize()

  if generateBoolean() or generateBoolean() then
    red = band(red + random(-size, size), 0xf)
    green = band(green + random(-size, size), 0xf)
    blue = band(blue + random(-size, size), 0xf)
  else
    alpha = band(alpha + random(-size, size), 0xf)
  end

  return packHalfBytes(red, green), packHalfBytes(blue, alpha)
end

function mutateStroke(painting)
  local i = random(1, #painting.strokes)
  stroke = painting.strokes[i]

  if painting.brush == "shadedTriangle" then
    local vertex = random(1, 3)

    if generateBoolean() then
      stroke[4 * vertex - 3], stroke[4 * vertex - 2] =
        mutatePosition(stroke[4 * vertex - 3], stroke[4 * vertex - 2])
    else
      stroke[4 * vertex - 1], stroke[4 * vertex - 0] =
        mutateHalfColor(stroke[4 * vertex - 1], stroke[4 * vertex - 0])
    end
  else
    local sign = 2 * random(0, 1) - 1
    local offset = sign * lshift(1, random(0, 7))

    local j = random(1, #stroke)
    stroke[j] = band(stroke[j] + offset, 0xff)
  end
end

function mutatePainting(painting)
  if generateBoolean() and generateBoolean() then
    if generateBoolean() then
      replaceStroke(painting)
    else
      moveStroke(painting)
    end
  else
    mutateStroke(painting)
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
        0.5 * size / 255 * canvasSize)
    end
  elseif painting.brush == "square" then
    for i, stroke in ipairs(painting.strokes) do
      local x, y, angle, size, redGreen, blueAlpha = unpack(stroke)

      local red, green = unpackHalfBytes(redGreen)
      local blue, alpha = unpackHalfBytes(blueAlpha)

      local halfSize = 0.5 * size / 255 * canvasSize

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
  elseif painting.brush == "shadedTriangle" then
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

      table.insert(
        vertices,
        {x1, y1, 0, 0, red1 / 15, green1 / 15, blue1 / 15, alpha1 / 15})

      table.insert(
        vertices,
        {x2, y2, 0, 0, red2 / 15, green2 / 15, blue2 / 15, alpha2 / 15})

      table.insert(
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
  elseif painting.brush == "triangle" then
    local vertices = {}

    for i, stroke in ipairs(painting.strokes) do
      local x1, y1, x2, y2, x3, y3, redGreen, blueAlpha = unpack(stroke)

      x1 = (2 * x1 / 255 - 0.5) * canvasWidth
      y1 = (2 * y1 / 255 - 0.5) * canvasHeight

      x2 = (2 * x2 / 255 - 0.5) * canvasWidth
      y2 = (2 * y2 / 255 - 0.5) * canvasHeight

      x3 = (2 * x3 / 255 - 0.5) * canvasWidth
      y3 = (2 * y3 / 255 - 0.5) * canvasHeight

      local red, green = unpackHalfBytes(redGreen)
      local blue, alpha = unpackHalfBytes(blueAlpha)

      red = red / 15
      green = green / 15
      blue = blue / 15
      alpha = alpha / 15

      table.insert(vertices, {x1, y1, 0, 0, red, green, blue, alpha})
      table.insert(vertices, {x2, y2, 0, 0, red, green, blue, alpha})
      table.insert(vertices, {x3, y3, 0, 0, red, green, blue, alpha})
    end

    triangleMesh:setVertices(vertices)
    love.graphics.draw(triangleMesh)
  else
    assert(false)
  end

  love.graphics.setCanvas()
end

local function rms4(x, y, z, w)
  return sqrt(0.25 * (x * x + y * y + z * z + w * w))
end

local function getDistance(image1, image2)
  local width1, height1 = image1:getDimensions()
  local width2, height2 = image2:getDimensions()
  assert(width1 == width2 and height1 == height2)

  local totalDistance = 0

  for y = 0, height1 - 1 do
    for x = 0, width1 - 1 do
      local r1, g1, b1, a1 = image1:getPixel(x, y)
      local r2, g2, b2, a2 = image2:getPixel(x, y)

      local distance = rms4(r2 - r1, g2 - g1, b2 - b1, a2 - a1)
      totalDistance = totalDistance + distance
    end
  end

  return totalDistance / (width1 * height1)
end

function love.load(arg)
  if #arg ~= 3 or arg[1] ~= "evolve" then
    print("Usage: love . evolve <source> <target>")
    love.event.quit(1)
    return
  end

  _, sourceFilename, targetFilename = unpack(arg)

  love.window.setTitle("Lima")
  love.window.setMode(1024, 512)
  referenceImageData = love.image.newImageData(sourceFilename)
  referenceImage = love.graphics.newImage(referenceImageData)

  print("Loading...")
  local success, result = loadPainting(targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generatePainting("square", 256)
  end

  triangleMesh = love.graphics.newMesh(3 * 256, "triangles")
  fonts = {}

  for size = 1, 15 do
    fonts[size] = love.graphics.newFont(512 * size / 15)
  end

  canvas = love.graphics.newCanvas(512, 512)
  drawPaintingToCanvas(parent, canvas)
  local parentImageData = canvas:newImageData()
  parentFitness = getDistance(parentImageData, referenceImageData)
  parentImage = love.graphics.newImage(parentImageData)
  print("Fitness: " .. parentFitness)
end

function love.update(dt)
  local child = clonePainting(parent)
  mutatePainting(child)

  drawPaintingToCanvas(child, canvas)
  local childImageData = canvas:newImageData()
  local childFitness = getDistance(childImageData, referenceImageData)

  if childFitness < parentFitness then
    parent = child
    parentFitness = childFitness
    parentImage = love.graphics.newImage(childImageData)

    print("Fitness: " .. parentFitness)
    savePainting(parent, targetFilename)
  end
end

function love.draw()
  love.graphics.reset()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(referenceImage, 0, 0)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(parentImage, 512, 0)
end

function love.quit()
  if parent and targetFilename then
    print("Saving...")
    savePainting(parent, targetFilename)
  end
end
