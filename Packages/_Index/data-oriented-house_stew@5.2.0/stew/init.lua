--!strict
--!optimize 2
--!native

local DEBUG = false

export type Components = { [Factory<any, any, any, ...any, ...any>]: any }

export type EntityData = Components

export type Add<D, E, C, A..., R...> = (factory: Factory<D, E, C, A..., R...>, entity: E, A...) -> C

export type Remove<D, E, C, A..., R...> = (factory: Factory<D, E, C, A..., R...>, entity: E, component: C, R...) -> ()

export type Archetype<D, E, C, A..., R...> = {
	create: Add<D, E, C, A..., R...>,
	delete: Remove<D, E, C, A..., R...>?,
	id: string,
	factory: Factory<D, E, C, A..., R...>,
}

type FactoryArgs<D, E, C, A..., R...> = {
	add: (Factory<D, E, C, A..., R...>, entity: E, A...) -> C,
	remove: (Factory<D, E, C, A..., R...>, entity: E, component: C, R...) -> ()?,
} & D

export type Factory<D, E, C, A..., R...> = {
	add: (entity: E, A...) -> C,
	remove: (entity: E, R...) -> (),
	added: (factory: Factory<D, E, C, A..., R...>, entity: E, component: C) -> ()?,
	removed: (factory: Factory<D, E, C, A..., R...>, entity: E, component: C) -> ()?,
	get: (entity: E) -> C?,
} & D

export type Tag<D> = Factory<D, any, boolean, (), ()>

type WorldArgs<W> = {
	built: <D, E, C, A..., R...>(world: World<W>, archetype: Archetype<D, E, C, A..., R...>) -> ()?,
	spawned: (world: World<W>, entity: any) -> ()?,
	killed: (world: World<W>, entity: any) -> ()?,
	added: <D, E, C, A..., R...>(
		world: World<W>,
		factory: Factory<D, E, C, A..., R...>,
		entity: E,
		component: C
	) -> ()?,
	removed: <D, E, C, A..., R...>(
		world: World<W>,
		factory: Factory<D, E, C, A..., R...>,
		entity: E,
		component: C
	) -> ()?,
} & W

export type World<W> = {
	_nextEntityId: number,
	_nextFactoryId: number,
	_factoryToData: { [Factory<any, any, any, ...any, ...any>]: Archetype<any, any, any, ...any, ...any> },
	_entityToData: { [any]: EntityData },
	_signatureToCollection: {
		[string]: CollectionData,
	},
	_universalCollection: CollectionData,
	_queryMeta: { __iter: (collection: Collection) -> () -> (any, EntityData) },
	_id: string,

	built: <D, E, C, A..., R...>(world: World<W>, archetype: Archetype<D, E, C, A..., R...>) -> ()?,
	spawned: (world: World<W>, entity: any) -> ()?,
	killed: (world: World<W>, entity: any) -> ()?,
	added: <D, E, C, A..., R...>(
		world: World<W>,
		factory: Factory<D, E, C, A..., R...>,
		entity: E,
		component: C
	) -> ()?,
	removed: <D, E, C, A..., R...>(
		world: World<W>,
		factory: Factory<D, E, C, A..., R...>,
		entity: E,
		component: C
	) -> ()?,

	factory: <D, E, C, A..., R...>(factoryArgs: FactoryArgs<D, E, C, A..., R...>) -> Factory<D, E, C, A..., R...>,
	tag: <D>(D) -> Tag<D>,
	entity: () -> string,
	kill: (entity: any) -> (),
	get: (entity: any) -> Components,
	query: (
		include: { Factory<any, any, any, ...any, ...any> }?,
		exclude: { Factory<any, any, any, ...any, ...any> }?
	) -> Collection,
} & W

local empty = table.freeze {}

local function toPackedString(x: number)
	local bytes = math.ceil(math.log(x + 1, 256))
	local str = if bytes <= 1
		then string.char(x)
		elseif bytes == 2 then string.char(x % 256, x // 256 % 256)
		elseif bytes == 3 then string.char(x % 256, x // 256 % 256, x // 256 ^ 2 % 256)
		elseif bytes == 4 then string.char(
			x // 256 ^ 0 % 256,
			x // 256 ^ 1 % 256,
			x // 256 ^ 2 % 256,
			x // 256 ^ 3 % 256
		)
		elseif bytes == 5 then string.char(
			x // 256 ^ 0 % 256,
			x // 256 ^ 1 % 256,
			x // 256 ^ 2 % 256,
			x // 256 ^ 3 % 256,
			x // 256 ^ 4 % 256
		)
		elseif bytes == 6 then string.char(
			x // 256 ^ 0 % 256,
			x // 256 ^ 1 % 256,
			x // 256 ^ 2 % 256,
			x // 256 ^ 3 % 256,
			x // 256 ^ 4 % 256,
			x // 256 ^ 5 % 256
		)
		elseif bytes == 7 then string.char(
			x // 256 ^ 0 % 256,
			x // 256 ^ 1 % 256,
			x // 256 ^ 2 % 256,
			x // 256 ^ 3 % 256,
			x // 256 ^ 4 % 256,
			x // 256 ^ 5 % 256,
			x // 256 ^ 6 % 256
		)
		else string.char(
			x // 256 ^ 0 % 256,
			x // 256 ^ 1 % 256,
			x // 256 ^ 2 % 256,
			x // 256 ^ 3 % 256,
			x // 256 ^ 4 % 256,
			x // 256 ^ 5 % 256,
			x // 256 ^ 6 % 256,
			x // 256 ^ 7 % 256
		)

	if DEBUG then
		print('nextId', ' = last ' .. x, 'str ' .. str)
	end

	return str
end

--[=[
	@class Stew
]=]
local Stew = {}

--[=[
	@within Stew

	A function to extract the unique entity and world ids encoded in World.entity() strings.

	Only works if there are less than 256 worlds. (This is reasonable right?)

	```lua
	local Stew = require(path.to.Stew)

	local w0 = Stew.world()
	local e00 = w0.entity()
	local e10 = w0.entity()
	local e20 = w0.entity()

	print(Stew.tonumber(e00)) -- 0, 0
	print(Stew.tonumber(e10)) -- 1, 0
	print(Stew.tonumber(e20)) -- 2, 0

	local w1 = Stew.world()

	local e01 = w1.entity()
	local e11 = w1.entity()
	local e21 = w1.entity()

	print(Stew.tonumber(e01)) -- 0, 1
	print(Stew.tonumber(e11)) -- 1, 1
	print(Stew.tonumber(e21)) -- 2, 1
	```
]=]
function Stew.tonumber(entity: string)
	-- Please don't make 256 or more worlds
	local world, a, b, c, d, e, f, g, h = string.byte(entity, 1, 9)
	local id = (h or 0) * 256 ^ 7
		+ (g or 0) * 256 ^ 6
		+ (f or 0) * 256 ^ 5
		+ (e or 0) * 256 ^ 4
		+ (d or 0) * 256 ^ 3
		+ (c or 0) * 256 ^ 2
		+ (b or 0) * 256
		+ a
	return id, world
end

local function iter(world: any)
	return function(collection: Collection)
		local i = #collection
		return function(): (any, EntityData)
			if i > 0 then
				local entity = collection[i] :: any
				i -= 1
				return entity,
					(world._entityToData[entity] :: any) or error(
						`Entity {entity} did not have any data! Unregistered but still in a collection`
					)
			else
				return nil, nil :: any
			end
		end
	end
end

local function hasAll(entityData: EntityData, factories: { Factory<any, any, any, ...any, ...any> })
	for _, factory in factories do
		if entityData[factory] == nil then
			return false
		end
	end

	return true
end

local function hasAny(entityData: EntityData, factories: { Factory<any, any, any, ...any, ...any> })
	for _, factory in factories do
		if entityData[factory] ~= nil then
			return true
		end
	end

	return false
end

local hashIds = {}
local function hash(
	world: any,
	include: { Factory<any, any, any, ...any, ...any> }?,
	exclude: { Factory<any, any, any, ...any, ...any> }?
)
	table.clear(hashIds)
	if include and include[1] ~= nil then
		for _, factory in include do
			local data = world._factoryToData[factory]
				or error('Passed a non-factory or a different world\'s factory into an include query!', 2)
			table.insert(hashIds, data.id)
		end
		table.sort(hashIds)
	end

	local signature = table.concat(hashIds)

	if exclude and exclude[1] ~= nil then
		table.clear(hashIds)
		for _, factory in exclude do
			local data = world._factoryToData[factory]
				or error('Passed a non-factory or a different world\'s factory into an include query!', 2)
			table.insert(hashIds, data.id)
		end
		table.sort(hashIds)

		signature ..= '!' .. table.concat(hashIds)
	end

	return signature
end

local function getCollectionData(
	world: any,
	include: { Factory<any, any, any, ...any, ...any> }?,
	exclude: { Factory<any, any, any, ...any, ...any> }?
)
	local signature = hash(world, include, exclude)
	if signature == '' then
		if DEBUG then
			print 'getCollection (universal)'
		end
		return world._universalCollection
	end

	local found = world._signatureToCollection[signature]
	if found then
		if DEBUG then
			print('getCollection (cached)', 's' .. signature)
		end
		return found
	end

	local indices = {}
	local entities =
		setmetatable({}, world._queryMeta :: { __iter: (collection: Collection) -> () -> (any, EntityData) })
	local collectionData = {
		entities = entities,
		indices = indices,
		include = include,
		exclude = exclude,
	}

	world._signatureToCollection[signature] = collectionData

	local index = 0
	local universal = world._universalCollection.entities
	for entity, data in universal do
		if (not include or hasAll(data, include)) and not (exclude and hasAny(data, exclude)) then
			index += 1
			entities[index] = entity
			indices[entity] = index
		end
	end

	if DEBUG then
		print('getCollection', 's' .. signature)
	end

	return collectionData
end

type CollectionData = typeof({
	entities = setmetatable({} :: { any }, {} :: { __iter: (collection: Collection) -> () -> (any, EntityData) }),
	indices = {} :: { [any]: number },
	include = nil :: { Factory<any, any, any, ...any, ...any> }?,
	exclude = nil :: { Factory<any, any, any, ...any, ...any> }?,
})

export type Collection = typeof(setmetatable(
	{} :: { any },
	{} :: { __iter: (collection: Collection) -> () -> (any, EntityData) }
))

local function tagAdd(factory, entity: any)
	return true
end

local function register<W>(world: World<W>, entity: any)
	if DEBUG then
		assert(not world._entityToData[entity], 'Attempting to register entity twice')
	end

	local entityData = {}
	world._entityToData[entity] = entityData

	if DEBUG then
		print('register', 'e' .. entity)
	end

	local universal = world._universalCollection
	local index = #universal.entities + 1
	universal.entities[index] = entity
	universal.indices[entity] = index

	if world.spawned then
		world.spawned(entity)
	end

	return entityData
end

local function unregister<W>(world: World<W>, entity: any)
	if DEBUG then
		assert(world._entityToData[entity], 'Attempting to unregister entity twice')
		print('unregister', 'e' .. entity)
	end

	local universal = world._universalCollection
	local last = #universal.entities

	local index = universal.indices[entity]
	local lastEntity = universal.entities[last]

	universal.entities[index], universal.entities[last] = lastEntity, nil
	universal.indices[lastEntity], universal.indices[entity] = index, nil

	world._entityToData[entity] = nil

	if world.killed then
		world.killed(entity)
	end
end

local function updateCollections<W>(world: World<W>, entity: any, entityData: EntityData)
	if DEBUG then
		print('updateCollections', 'e' .. entity)
	end

	-- local t0 = os.clock()

	for signature, collectionData in world._signatureToCollection do
		local collectionInclude, collectionExclude = collectionData.include, collectionData.exclude

		local entities, indices = collectionData.entities, collectionData.indices
		local index = indices[entity] :: number?

		local shouldInsert = true

		if collectionInclude then
			for _, factory in collectionInclude do
				if entityData[factory] == nil then
					shouldInsert = false
					break
				end
			end
		end

		if collectionExclude and shouldInsert then
			for _, factory in collectionExclude do
				if entityData[factory] ~= nil then
					shouldInsert = false
					break
				end
			end
		end

		if shouldInsert then
			if not index then
				local newIndex = #entities + 1
				entities[newIndex] = entity
				indices[entity] = newIndex
			end
		elseif index then
			local lastEntity = table.remove(entities :: any)
			indices[entity] = nil
			if lastEntity ~= entity then
				entities[index] = lastEntity
				indices[lastEntity] = index
			end
		end
	end

	-- local t1 = os.clock()
	-- print(t1 - t0)
end

--[=[
	@within World
	@interface Archetype
	.factory Factory<D, E, C, A..., R...>,
	.create (factory, entity: E, A...) -> C,
	.delete (factory, entity: E, component: C, R...) -> ()
	.signature string,
]=]

--[=[
	@within Stew
	@interface World
	. added (world: Worldfactory: Factory, entity: any, component: any)?
	. removed (world: Wo, rldfactory: Factory, entity: any, component: any)?
	. spawned (world: Worl, dentity: any) -> ()?
	. killed (world: World, entity: any) -> ()?
	. built (world: World, archetype: Archetype) -> ()?
]=]

Stew._nextWorldId = -1

--[=[
	@within Stew
	@return World

	Creates a new world.

	```lua
	-- Your very own world to toy with
	local myWorld = Stew.world {}

	-- If you'd like to listen for certain events, you can define these callbacks in the table or outside like so:

	-- Called whenever a new factory is built
	function myWorld:built(archetype: Archetype) end

	-- Called whenever a new entity is registered
	function myWorld:spawned(entity) end

	-- Called whenever an entity is unregistered
	function myWorld:killed(entity) end

	-- Called whenever an entity recieves a component
	function myWorld:added(factory, entity, component) end

	-- Called whenever an entity loses a component
	function myWorld:removed(factory, entity, component) end
	```
]=]
function Stew.world<W>(worldArgs: WorldArgs<W>)
	--[=[
		@class World

		Worlds are containers for everything in your ECS. They hold all the state and factories you define later. They are very much, an isolated tiny world.

		"Oh what a wonderful world!" - Louis Armstrong
	]=]
	local world = worldArgs :: World<W>
	world._nextFactoryId = -1
	world._nextEntityId = -1
	world._factoryToData = {}
	world._entityToData = {}
	world._signatureToCollection = {}

	Stew._nextWorldId += 1
	world._id = toPackedString(Stew._nextWorldId)
	world._queryMeta = { __iter = iter(world) }
	world._universalCollection = {
		entities = setmetatable({} :: { any }, world._queryMeta),
		indices = {},
	}

	if DEBUG then
		print('Stew.world', '= w' .. world._id)
	end

	--[=[
		@within World
		@interface FactoryArgs
		.add (factory: Factory, entity: E, A...) -> C
		.remove (factory: Factory, entity: E, component: C, R...) -> ()?
		.[any] any
	]=]

	--[=[
		@within World
		@interface Factory
		.add (entity: E, A...) -> C
		.remove (entity: E, component: C, R...) -> ()
		.get (entity: E),
		.added (Factory, entity: E, component: C) -> ()?
		.removed (Factory, entity: E, component: C) -> ()?
		.[any] any
	]=]

	--[=[
		@within World
		@param factoryArgs FactoryArgs
		@return Factory

		Creates a new factory from an `add` constructor and optional `remove` destructor. The arguments table is mutated and recycled; you may define any extra data and access it from the factory to store useful metadata like identifiers.

		```lua
		local world = Stew.world {}

		local position = world.factory {
			add = function(factory, entity: any, x: number, y: number, z: number)
				return Vector3.new(x, y, z)
			end,
		}

		print(position.data)
		-- nil

		print(position.add('A really cool entity', 5, 7, 9))
		-- Vector3.new(5, 7, 9)

		position.remove('A really cool entity')

		local body = world.factory {
			add = function(factory, entity: Instance, model: Model)
				model.Parent = entity
				return model
			end,
			remove = function(factory, entity: Instance, component: Model)
				component:Destroy()
			end,
			data = 'A temple one might say...',
		}

		print(body.data)
		-- 'A temple one might say...'

		print(body.add(LocalPlayer, TemplateModel))
		-- TemplateModel

		body.remove(LocalPlayer)

		-- If you'd like to listen for interesting events to happen, define these callbacks:

		-- Called when an entity recieves this factory's component
		function body:added(entity: Instance, component: Model) end

		-- Called when an entity loses this factory's component
		function body:removed(entity: Instance, component: Model) end
		```
	]=]
	function world.factory<D, E, C, A..., R...>(factoryArgs: FactoryArgs<D, E, C, A..., R...>)
		--[=[
			@class Factory

			Factories are little objects responsible for adding and removing their specific type of component from entities. They are also used to access their type of component from entities and queries. They are well, component factories!
		]=]
		local factory = (factoryArgs :: any) :: Factory<D, E, C, A..., R...>

		world._nextFactoryId += 1

		local archetype = {
			factory = factory,
			id = toPackedString(world._nextFactoryId),
			create = factoryArgs.add,
			delete = factoryArgs.remove,
		}

		if DEBUG then
			print('world.factory', 'w' .. world._id, 'f' .. archetype.id)
		end

		--[=[
			@within Factory
			@param entity any
			@param ... any
			@return Component

			Adds the factory's type of component to the entity. If the component already exists, it just returns the old component and does not perform any further changes.

			Anything can be an Entity, if an unregistered object is given a component it is registered as an entity and fires the world `spawned` callback.

			Fires the world and factory `added` callbacks.

			```lua
			local World = require(path.to.world)
			local Move = require(path.to.move.factory)
			local Chase = require(path.to.chase.factory)
			local Model = require(path.to.model.factory)

			local enemy = World.entity()
			Model.add(enemy)
			Move.add(enemy)
			Chase.add(enemy)

			-- continues to below example
			```
		]=]
		function factory.add(entity: E, ...: A...): C
			if DEBUG then
				print(
					'factory.add',
					'w' .. world._id,
					'f' .. archetype.id,
					if type(entity) == 'string' then 'e' .. ({ entity })[1] else entity,
					'args',
					...
				)
			end

			local entityData = world._entityToData[entity]
			if not entityData then
				entityData = register(world, entity)
			elseif entityData[factory] then
				return entityData[factory]
			end

			local component = archetype.create(factory, entity, ...)
			if component == nil then
				return component
			end

			entityData[factory] = component
			updateCollections(world, entity, entityData)

			if factory.added then
				factory.added(factory, entity, component)
			end

			if world.added then
				world.added(world, factory, entity, component)
			end

			return component
		end

		--[=[
			@within Factory
			@param entity any
			@param ... any
			@return void?

			Removes the factory's type of component from the entity. If the entity is unregistered, nothing happens.

			Fires the world and factory `removed` callbacks.

			If this is the last component the entity has, it kills the entity and fires the world `killed` callback.

			```lua
			-- continued from above example

			task.wait(5)

			Chase.remove(entity)
			Move.remove(entity)
			```
		]=]
		function factory.remove(entity: E, ...: R...)
			if DEBUG then
				print(
					'factory.remove',
					'w' .. world._id,
					'f' .. archetype.id,
					if type(entity) == 'string' then 'e' .. ({ entity })[1] else entity,
					'args',
					...
				)
			end

			local entityData = world._entityToData[entity]
			if not entityData then
				return
			end

			local component = entityData[factory]
			if not component then
				return
			end

			if archetype.delete then
				archetype.delete(factory, entity, component, ...)
			end

			entityData[factory] = nil
			updateCollections(world, entity, entityData)

			if factory.removed then
				factory.removed(factory, entity, component)
			end

			if world.removed then
				world.removed(world, factory, entity, component)
			end

			if not next(entityData) then
				unregister(world, entity)
			end
		end

		--[=[
			@within Factory
			@param entity any
			@return Component?

			Returns the factory's type of component from the entity if it exists.

			If component is not a table or other referenced type it will not be mutable. Use `World.get` instead if this is a requirement.
			```lua
			local World = require(path.to.World)

			local Fly = World.factory { ... }

			for _, player in Players:GetPlayers() do
				Fly.add(player)
			end

			onPlayerTouched(BlackholeBrick, function(player: Player)
				local fly = Fly.get(player)
				if fly and fly.speed < Constants.LightSpeed then
					World.kill(player)
				end
			end)
			```
		]=]
		function factory.get(entity: E): C?
			local entityData = world._entityToData[entity]
			if DEBUG then
				print(
					'factory.get',
					'w' .. world._id,
					'f' .. archetype.id,
					if type(entity) == 'string' then 'e' .. ({ entity })[1] else entity
				)
			end
			return if entityData then entityData[factory] else nil
		end

		world._factoryToData[factory] = archetype

		if world.built then
			world.built(world, archetype :: any)
		end

		return factory :: any
	end

	--[=[
		@within World
		@param tagArgs { [any]: any }
		@return Factory

		Syntax sugar for defining a factory that adds a `true` component. It is used to mark the *existence* of the component, like a tag does.

		```lua
		local world = Stew.world {}

		local sad = world.tag {}
		local happy = world.tag {}
		local sleeping = world.tag {}
		local poisoned = world.tag {}

		local allHappyPoisonedSleepers = world.query { happy, poisoned, sleeping }
		```
	]=]
	function world.tag<D>(tagArgs: D)
		if DEBUG then
			print 'world.tag'
		end

		local newTag = tagArgs :: any
		newTag.add = tagAdd
		newTag.remove = nil

		local a = world.factory(newTag) :: Tag<D>
		return a
	end

	--[=[
		@within World
		@return string

		Creates an arbitrary entity. Keep in mind, in Stew, *anything* can be an Entity (except nil). If you don't have a pre-existing object to use as an entity, this will create a unique-across-worlds identifier you can use.

		Can be sent over remotes and is unique across worlds!

		```lua
		local World = require(path.to.World)
		local Move = require(path.to.move.factory)
		local Chase = require(path.to.chase.factory)
		local Model = require(path.to.model.factory)

		local enemy = World.entity()
		Model.add(enemy)
		Move.add(enemy)
		Chase.add(enemy)

		-- continues to below example
		```
	]=]
	function world.entity()
		world._nextEntityId += 1

		if DEBUG then
			print('world.entity', 'e' .. world._nextEntityId)
		end

		return world._id .. toPackedString(world._nextEntityId)
	end

	--[=[
		@within World

		Removes all components from an entity and unregisters it. Can miss components if a remove function adds components back to the entity, not recommended.

		For optimization reasons, the entity is taken out of all collections except the universal collection before calling any remove functions. Beware of this behavior!

		Fires the world `killed` callback.

		```lua
		-- continued from above example

		task.wait(5)

		World.kill(enemy)
		```
	]=]
	function world.kill(entity: any)
		if DEBUG then
			print('world.entity', if type(entity) == 'string' then 'e' .. ({ entity })[1] else entity, 'w' .. world._id)
		end

		local entityData = world._entityToData[entity]
		if not entityData then
			return
		end

		for _, collectionData in world._signatureToCollection do
			local entities, indices = collectionData.entities, collectionData.indices
			local index = indices[entity]
			if not index then
				continue
			end

			local lastEntity = table.remove(entities :: any)
			indices[entity] = nil
			if lastEntity ~= entity then
				entities[index] = lastEntity
				indices[lastEntity] = index
			end
		end

		for factory, component in entityData do
			local archetype = world._factoryToData[factory]
			if archetype.delete then
				archetype.delete(factory, entity)
			end

			if factory.removed then
				(factory.removed :: any)(factory, entity, component)
			end

			if world.removed then
				world.removed(world, factory, entity, component)
			end
		end

		unregister(world, entity)
	end

	--[=[
		@within World
		@type Components { [Factory]: Component }
	]=]

	--[=[
		@within World
		@tag Do Not Modify
		@return Components

		Gets all components of an entity in a neat table you can iterate over.

		This is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.

		```lua
		local World = require(path.to.world)
		local Move = require(path.to.move.factory)
		local Chase = require(path.to.chase.factory)
		local Model = require(path.to.model.factory)

		local enemy = World.entity()

		Model.add(enemy)

		local components = world.get(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model

		Move.add(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model
		-- Move, BodyMover

		Chase.add(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model
		-- Move, BodyMover
		-- Chase, TargetInstance

		print(world.get(entity)[Chase]) -- TargetInstance
		```
	]=]
	function world.get(entity: any): Components
		if DEBUG then
			print('world.entity', if type(entity) == 'string' then 'e' .. ({ entity })[1] else entity, 'w' .. world._id)
		end

		return world._entityToData[entity] or empty
	end

	--[=[
		@within World
		@tag Do Not Modify
		@param include { Factory }?
		@param exclude { Factory }?
		@return { Entity }

		Gets a set of all entities that have all included components, and do not have any excluded components. (This is the magic sauce of it all!)

		This is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.

		If passed empty arrays or nil, will return the universal collection.

		```lua
		local World = require(path.to.world)
		local Invincible = require(path.to.invincible.tag)
		local Poisoned = require(path.to.poisoned.factory)
		local Health = require(path.to.health.factory)
		local Color = require(path.to.color.factory)

		local poisonedHealths = world.query({ Poisoned, Health }, { Invincible })

		-- This is a very cool system
		RunService.Heartbeat:Connect(function(deltaTime)
			for entity, components in poisonedHealths do
				local health = components[Health]
				local poison = components[Poison]
				health.current -= deltaTime * poison

				if health.current < 0 then
					World.kill(entity)
				end
			end
		end)

		-- This is another very cool system
		RunService.RenderStepped:Connect(function(deltaTime)
			for entity, components in world.query { Poisoned, Color } do
				local color = components[Color]
				color.hue += deltaTime * (120 - color.hue)
				color.saturation += deltaTime * (1 - color.saturation)
			end
		end)
		```
	]=]
	function world.query(
		include: { Factory<any, any, any, ...any, ...any> }?,
		exclude: { Factory<any, any, any, ...any, ...any> }?
	): Collection
		if DEBUG then
			local includes = {}
			local excludes = {}

			if include then
				for _, inc in include do
					table.insert(includes, 'f' .. world._factoryToData[inc].id .. ' ' .. tostring(inc.data))
				end
			end

			if exclude then
				for _, exc in exclude do
					table.insert(includes, tostring(exc.data) .. ' f' .. world._factoryToData[exc].id)
				end
			end

			local t = 'world.query\n\tinclude ' .. table.concat(includes, ', ')
			if excludes and #excludes > 0 then
				t ..= '\n\texclude ' .. table.concat(excludes, ', ')
			end
			print(t)
		end

		local collection = getCollectionData(world, include, exclude).entities

		if DEBUG then
			local entities = {}
			for entity in collection do
				local e = if type(entity) == 'string' then 'e' .. ({ entity })[1] else tostring(entity)
				table.insert(entities, e)
			end
			print('{\n\t' .. table.concat(entities, ',\n\t') .. '\n}')
		end

		return collection
	end

	return world
end

return Stew
