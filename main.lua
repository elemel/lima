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

function splitByte(byte)
  local upperHalf = rshift(band(byte, 0xf0), 4)
  local lowerHalf = band(byte, 0xf)

  return upperHalf, lowerHalf
end

function joinByte(upperHalf, lowerHalf)
  upperHalf = band(upperHalf, 0xf)
  lowerHalf = band(lowerHalf, 0xf)

  return bor(lshift(upperHalf, 4), lowerHalf)
end

function loadScene(filename)
  local success, result = pcall(dofile, targetFilename)

  if success then
    result.brush = result.brush or "circle"
  end

  return success, result
end

function saveScene(scene, filename)
  local file = io.open(filename, "w")
  file:write("return {\n")
  file:write("  brush = \"" .. scene.brush .. "\",\n")
  file:write("\n")
  file:write("  layers = {\n")

  for i, layer in ipairs(scene.layers) do
    file:write("    {" .. table.concat(layer, ", ") .. "},\n")
  end

  file:write("  },\n")
  file:write("}\n")
  file:close()
end

function cloneScene(scene)
  local layers = {}

  for i, layer in ipairs(scene.layers) do
    layers[i] = {unpack(layer)}
  end

  return {
    brush = scene.brush,
    layers = layers,
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

function generateLayer(brush)
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
  else
    assert(false)
  end
end

function generateScene(brush, size)
  local layers = {}

  for i = 1, size do
    layers[i] = generateLayer(brush)
  end

  return {
    brush = brush,
    layers = layers,
  }
end

function mutateLayer(layer)
  local i = random(1, #layer)

  local upperHalf, lowerHalf = splitByte(layer[i])

  if generateBoolean() then
    upperHalf = generateByte()
  else
    lowerHalf = generateByte()
  end

  layer[i] = joinByte(upperHalf, lowerHalf)
end

function mutateScene(scene)
  if generateBoolean() then
    -- Replace layer
    local i = random(1, #scene.layers)
    local j = random(1, #scene.layers)
    local layer = generateLayer(scene.brush)
    table.remove(scene.layers, i)
    table.insert(scene.layers, j, layer)
  else
    -- Mutate layer
    local i = random(1, #scene.layers)
    mutateLayer(scene.layers[i])
  end
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
  local success, result = loadScene(targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generateScene("shadedTriangle", 256)
  end

  triangleMesh = love.graphics.newMesh(3 * 256, "triangles")
end

local function drawSceneToCanvas(scene, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  local width, height = canvas:getDimensions()
  love.graphics.scale(width, height)

  if scene.brush == "circle" then
    for i, layer in ipairs(scene.layers) do
      local x, y, size, redGreen, blueAlpha = unpack(layer)

      local red, green = splitByte(redGreen)
      local blue, alpha = splitByte(blueAlpha)

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)
      love.graphics.circle("fill", x / 255, y / 255, 0.5 * size / 255)
    end
  elseif scene.brush == "square" then
    for i, layer in ipairs(scene.layers) do
      local x, y, angle, size, redGreen, blueAlpha = unpack(layer)

      local red, green = splitByte(redGreen)
      local blue, alpha = splitByte(blueAlpha)

      love.graphics.setColor(red / 15, green / 15, blue / 15, alpha / 15)

      love.graphics.push()
      love.graphics.rotate(2 * pi * angle / 256)

      love.graphics.rectangle(
        "fill",
        x / 255 - 0.5 * size / 255,
        y / 255 - 0.5 * size / 255,
        size / 255,
        size / 255)

      love.graphics.pop()
    end
  elseif scene.brush == "shadedTriangle" then
    local vertices = {}

    for i, layer in ipairs(scene.layers) do
      local x1, y1, redGreen1, blueAlpha1,
        x2, y2, redGreen2, blueAlpha2,
        x3, y3, redGreen3, blueAlpha3 = unpack(layer)

      x1 = 2 * x1 / 255 - 0.5
      y1 = 2 * y1 / 255 - 0.5

      x2 = 2 * x2 / 255 - 0.5
      y2 = 2 * y2 / 255 - 0.5

      x3 = 2 * x3 / 255 - 0.5
      y3 = 2 * y3 / 255 - 0.5

      local red1, green1 = splitByte(redGreen1)
      local blue1, alpha1 = splitByte(blueAlpha1)

      local red2, green2 = splitByte(redGreen2)
      local blue2, alpha2 = splitByte(blueAlpha2)

      local red3, green3 = splitByte(redGreen3)
      local blue3, alpha3 = splitByte(blueAlpha3)

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

function love.draw()
  if not canvas then
    canvas = love.graphics.newCanvas(512, 512)
    drawSceneToCanvas(parent, canvas)
    local parentImageData = canvas:newImageData()
    parentFitness = getDistance(parentImageData, referenceImageData)
    parentImage = love.graphics.newImage(parentImageData)
    print("Fitness: " .. parentFitness)
  end

  love.graphics.reset()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setBlendMode("alpha")
  love.graphics.draw(referenceImage, 0, 0)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(parentImage, 512, 0)

  local child = cloneScene(parent)
  mutateScene(child)

  drawSceneToCanvas(child, canvas)
  local childImageData = canvas:newImageData()
  local childFitness = getDistance(childImageData, referenceImageData)

  if childFitness < parentFitness then
    parent = child
    parentFitness = childFitness
    parentImage = love.graphics.newImage(childImageData)

    print("Fitness: " .. parentFitness)
    saveScene(parent, targetFilename)
  end
end

function love.quit()
  if parent and targetFilename then
    print("Saving...")
    saveScene(parent, targetFilename)
  end
end
