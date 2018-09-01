classdef DAGraph < handle
    %DAGRAPH Directed acyclic graph
    %   Detailed explanation goes here
    properties (Constant)
        MAX_NODES = 50;
    end
    
    properties
        dict
        edges
        n_nodes
    end
    
    methods
        
        function [obj] = DAGraph()
            obj.dict = containers.Map('KeyType', 'int32', ...
                                       'ValueType', 'uint8');
            %edges-parameter is the directed acyclic graph matrix, which
            %has tracker id-tags as its values
            obj.edges = sparse(zeros(DAGraph.MAX_NODES));
            obj.n_nodes = 0;
        end
        
        
        function [idx] = addNode(obj, el_id)
            validateNodeAddition(obj);
            idx = obj.n_nodes + 1;
            obj.dict(el_id) = idx;
            obj.n_nodes = idx;
        end
        
        
        function [idx] = getNode(obj, el_id)
            validateId(obj, el_id)
            idx = obj.dict(el_id);
        end
        
       
        function [obj] = setEdge(obj, id_from, id_to, val)
            % check that the edge can be created. Assign if the result is
            % valid.
            validateId(obj, id_from);
            validateId(obj, id_to);
            new_edges = obj.edges;
            idx_from = obj.dict(id_from);
            idx_to = obj.dict(id_to);
            new_edges(idx_from, idx_to) = val;
            validateEdges(new_edges);
            obj.edges = new_edges;
        end
        
        %getChildren() retrieves the id-numbers of all the children of a
        %particular node.
        function [children] = getChildren(obj, el_id)
            idx = obj.getNode(el_id);
            child_mask = full(obj.edges(idx, 1:obj.n_nodes));
            children = child_mask(child_mask > 0);
        end
        
    end  % methods
    
    
    methods (Access = private)
        
        function [idx] = getRootNodes(obj)
            idx = find(~sum(obj.edges, 2));
        end
        
        
        function [bool] = isFull(obj)
            bool = obj.n_nodes == DAGraph.MAX_NODES;
        end
        
        
        function [el_id] = getElementId(obj, idx_mask)
            ids = obj.dict.keys();
            vals = cell2mat(obj.dict.values);
            [~, sort_idx] = sort(vals);
            ids = ids(sort_idx);
            el_id = ids(idx_mask);
        end
        
        
    end  % private methods
   
end



function validateNodeAddition(obj)
    if obj.isFull()
        error('DAGraph:outOfSpace', 'No more space in a DAGraph.')
    end
end


function validateEdges(edges)
    if ~graphisdag(edges)
        error('DAGraph:invalidEdge', ...
              'New edge would cause a cyclic dependency.')
    end
end


function validateId(obj, id)
    if ~obj.dict.isKey(id)
        error('DAGraph:elementNotFound', ...
              'Element not found from the network.')
    end
end
