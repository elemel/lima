function saveScene(scene, filename)
  local file = io.open(filename, "w")
  file:write("return {\n")

  for i, layer in ipairs(scene) do
    local x, y, diameter, red, green, blue, alpha = unpack(layer)
    file:write("  {" ..
      x .. ", " ..
      y .. ", " ..
      diameter .. ", " ..
      red .. ", " ..
      green .. ", " ..
      blue .. ", " ..
      alpha .. "},\n")
  end

  file:write("}\n")
  file:close()
end

function cloneScene(scene)
  local clone = {}

  for i, layer in ipairs(scene) do
    clone[i] = {unpack(layer)}
  end

  return clone
end

function randomByte()
  return love.math.random(0, 255)
end

function generateLayer()
  local x = randomByte()
  local y = randomByte()
  local diameter = randomByte()

  local red = randomByte()
  local green = randomByte()
  local blue = randomByte()
  local alpha = randomByte()

  return {x, y, diameter, red, green, blue, alpha}
end

function generateScene(size)
  local scene = {}

  for i = 1, size do
    scene[i] = generateLayer()
  end

  return scene
end

function mutateLayerByte(layer)
  local i = love.math.random(1, #layer)
  layer[i] = randomByte()
end

function mutateLayerBit(layer)
  local i = love.math.random(1, #layer)
  local j = love.math.random(0, 7)
  layer[i] = bit.bxor(layer[i], bit.lshift(1, j))
end

function mutateScene(scene)
  local i = love.math.random(1, 4)

  if i == 1 then
    -- Replace scene
    for j = 1, #scene do
      scene[j] = generateLayer()
    end
  elseif i == 2 then
    -- Replace layer
    local j = love.math.random(1, #scene)
    local k = love.math.random(1, #scene)
    local layer = generateLayer()
    table.remove(scene, j)
    table.insert(scene, k, layer)
  elseif i == 3 then
    -- Replace layer byte
    local j = love.math.random(1, #scene)
    mutateLayerByte(scene[j])
  else
    -- Replace layer bit
    local j = love.math.random(1, #scene)
    mutateLayerBit(scene[j])
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
  local success, result = pcall(dofile, targetFilename)

  if success then
    parent = result
  else
    print("Loading error: " .. result)
    parent = generateScene(256)
  end
end

local function drawSceneToCanvas(scene, canvas)
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  local width, height = canvas:getDimensions()
  love.graphics.scale(width, height)

  for i, layer in ipairs(scene) do
    local x, y, diameter, red, green, blue, alpha = unpack(layer)
    love.graphics.setColor(red / 255, green / 255, blue / 255, alpha / 255)
    love.graphics.circle("fill", x / 255, y / 255, 0.5 * diameter / 255)
  end

  love.graphics.setCanvas()
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

      distance = (0.25 * ((r2 - r1) ^ 2 + (g2 - g1) ^ 2 + (b2 - b1) ^ 2 + (a2 - a1) ^ 2)) ^ 0.5
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
