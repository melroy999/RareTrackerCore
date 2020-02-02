LinkedSet = {
	__n = 0,
	__raw_data_table = {},
	__front = nil,
	__back = nil
}

-- Create a new and empty linked list.
function LinkedSet:New(o)
	o = o or {
		__n = 0,
		__raw_data_table = {},
		__front = nil,
		__back = nil
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function LinkedSet:Clear()
	self.__n = 0
	self.__raw_data_table = {}
	self.__front = nil
	self.__back = nil
end

function LinkedSet:AddFront(v)
	if self.__raw_data_table[v] == nil then
		-- Add the item to the front of the set.
		self.__n = self.__n + 1
		
		if self.__front == nil then
			-- This is the first element we insert.
			self.__raw_data_table[v] = {__previous = nil, __next = nil}
			self.__front = v
			self.__back = v
		else
			-- Replace the current first element with the new one.
			self.__raw_data_table[v] = {__previous = nil, __next = self.__front}
			self.__raw_data_table[self.__front].__previous = v
			self.__front = v
		end
	end
end

function LinkedSet:AddBack(v)
	if self.__raw_data_table[v] == nil then
		-- Add the item to the front of the set.
		self.__n = self.__n + 1
		
		if self.__back == nil then
			-- This is the first element we insert.
			self.__raw_data_table[v] = {__previous = nil, __next = nil}
			self.__front = v
			self.__back = v
		else
			-- Replace the current last element with the new one.
			self.__raw_data_table[v] = {__previous = self.__back, __next = nil}
			self.__raw_data_table[self.__back].__next = v
			self.__back = v
		end
	end
end

-- Replace v1 with v2.
function LinkedSet:Replace(v1, v2)
	if self.__raw_data_table[v2] ~= nil then
		print("v2 is already in the set.")
	elseif self.__raw_data_table[v1] == nil then
		print("v1 does not exist.")
	else
		local node = self.__raw_data_table[v1]
	
		-- Create a new node and set the appropriate pointers.
		self.__raw_data_table[v2] = {__previous = node.__previous, __next = node.__next}
		
		if node.__previous ~= nil then
			self.__raw_data_table[node.__previous].__next = v2
		else
			self.__front = v2
		end
		
		if node.__next ~= nil then
			self.__raw_data_table[node.__next].__previous = v2
		else
			self.__back = v2
		end

		-- Remove the original.
		self.__raw_data_table[v1] = nil
	end
end

function LinkedSet:Swap(v1, v2)
	local node1, node2 = self.__raw_data_table[v1], self.__raw_data_table[v2]
	
	-- Check if the nodes both exist.
	if node1 ~= nil and node2 ~= nil and v1 ~= v2 then
		-- First, replace v1 with a dummy variable.
		self:Replace(v1, "##"..v2)
		
		-- Next, replace v2 with v1.
		self:Replace(v2, v1)
		
		-- Finally, restore the name of the v2 variable.
		self:Replace("##"..v2, v2)
	end
end

function LinkedSet:SwapNeighbors(v1, v2)
	local node1, node2 = self.__raw_data_table[v1], self.__raw_data_table[v2]
	
	if node1.__next ~= v2 then
		print("v2 should follow v1 as the next node.")
		return
	end
	
	-- Check if the nodes both exist.
	if node1 ~= nil and node2 ~= nil and v1 ~= v2 then
		if node1.__previous ~= nil then
			self.__raw_data_table[node1.__previous].__next = v2
		else
			self.__front = v2
		end
		
		if node2.__next ~= nil then
			self.__raw_data_table[node2.__next].__previous = v1
		else
			self.__back = v1
		end
		
		local node1_prev, node2_succ = node1.__previous, node2.__next
		node2.__next = v1
		node1.__previous = v2
		node2.__previous = node1_prev
		node1.__next = node2_succ
	end
end

function LinkedSet:Remove(v)
	if self.__raw_data_table[v] ~= nil then
		-- Make sure that the pointers stay correct.
		if self.__n == 1 then
			self.__front = nil
			self.__back = nil
		else
			-- The node we want to remove.
			local node = self.__raw_data_table[v]
			
			if node.__previous == nil then
				-- The node is the first in the list.
				self.__raw_data_table[node.__next].__previous = nil
				self.__front = node.__next
			elseif node.__next == nil then
				-- The node is the last in the list.
				self.__raw_data_table[node.__previous].__next = nil
				self.__back = node.__previous
			else
				-- The node is somewhere in the middle of the list.
				local pred_id, succ_id = node.__previous, node.__next
				local pred, succ = self.__raw_data_table[pred_id], self.__raw_data_table[succ_id]
				
				pred.__next = succ_id
				succ.__previous = pred_id
			end
		end
	
		-- Remove the item from the set.
		self.__raw_data_table[v] = nil
		self.__n = self.__n - 1
	end
end

function LinkedSet:PrintList()
  self:ForEach(
    function(v, _)
      print(v)
    end
  )
end

function LinkedSet:ForEach(__function)
	if self.__n > 0 then
		local v = self.__front
		
		while v ~= nil do
			__function(v, self.__raw_data_table[v])
			v = self.__raw_data_table[v].__next
		end
	end
end








