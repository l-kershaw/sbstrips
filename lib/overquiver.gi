InstallMethod(
    IsOneRegularQuiver,
    "for quivers",
    [IsQuiver],
    function( quiver )
        local
            v,      # Vertex variable
            verts;  # Vertices of <quiver>
        
        # Test vertex degrees
        verts := VerticesOfQuiver( quiver );
		
        for v in verts do
            if InDegreeOfVertex( v ) <> 1 or OutDegreeOfVertex( v ) <> 1 then
                return false;
            fi;
        od;
		
        return true;
    end
);

InstallMethod(
    QuiverOfQuiverPath,
    "for paths in a quiver",
    [IsPath],
    function( path )

    # Access original quiver from <path>'s family
    # We isolate this utility from other functions in case future versions of
	#  QPA operate differently

    return FamilyObj( path )!.quiver;
    end
);

InstallMethod(
	OneRegQuivIntActionFunction,
	"for 1-regular quivers",
	[ IsQuiver ],
	function ( quiver )
		local
			func;	# Function variable
			
		if HasOneRegQuivIntActionFunction( quiver ) then
			return OneRegQuivIntActionFunction( quiver );
		
		# Test input
		elif not IsOneRegularQuiver( quiver ) then
			Error( "The given quiver\n", quiver, "\nis not 1-regular!" );
			
		else
			# Write (nonrecursive!) function
			# In our convention, vertices are like
			#   i+1 --> i
			# and arrows are like
			#   --{a+1}--> vertex --{a}-->
			func := function( x, K );
				local
					k,	# Integer variable
					y;	# Quiver generator variable
					
				# Test input
				if not x in GeneratorsOfQuiver( quiver ) then
					Error( "The first argument\n", x, "\nmust be a vertex or ",
					 "an arrow of the quiver\n", quiver );
				elif not IsInt( K ) then
					Error( "The second argument\n", K,
					 "\nmust be an integer" );
					 
				else
					x := y;
					k := K;
					
					while k <> 0 do
						if IsQuiverVertex( x ) and k > 0 then
							x := TargetOfPath( OutgoingArrowsOfVertex(x)[1] );
							k := k - 1;
							
						elif IsQuiverVertex( x ) and k < 0 then
							x := SourceOfPath( IncomingArrowsOfVertex(x)[1] );
							k := k + 1;
							
						elif IsArrow( x ) and k > 0 then
							x := OutgoingArrowsOfVertex( TargetOfPath(x) )[1];
							k := k-1;
							
						elif IsArrow( x ) and k < 0 then
							x := IncomingArrowsOfVertex( SourceOfPath(x) )[1];
							k := k + 1;
						fi;
					od;
					
					return x;
				fi;
			end;
			
			return func;
		fi;
	end
);
										
%				if K = 0 then
%					return y;
%				elif K > 0 then
%					if IsQuiverVertex( y ) then
%						return f( IncomingArrowsOfVertex( y )[1], K-1 );
%					else
%						return f( SourceOfPath( y ), K-1 );
%					fi;
%				else
%					if IsQuiverVertex( y ) then
%						return f( OutgoingArrowsOfVertex( y )[1], K+1 );
%					else
%						return f( TargetOfPath( y ), K+1 );
%					fi;
%				fi;
%			end;
%		fi;
%	end
%);

InstallMethod(
    OneRegQuivIntAction,
    "method for a generator vertex of a 1-regular quiver and an integer",
    [IsPath, IsInt],
    function( x, k )
        local
            f,      # Recursive function
            j,      # Integer variable
            quiv,   # Quiver of <vert>
            y;      # Generator variable

        quiv := QuiverOfQuiverPath( x );

        # Preliminary test
        # When a quiver is not 1-regular, generators of the quiver may not have
		#  a "predecessor" or a "successor".
        if not IsOneRegularQuiver( quiv ) then
            TryNextMethod();

        else
            # Predecessors and successors are defined only for generators of
			#  the quiver.
            if LengthOfPath( x ) >= 2 then
                Error( "The input path\n", x, "\nmust be a vertex or arrow." );

            else
                f := function( y, K );
					if K = 0 then
						return y;
					elif K > 0 then
						if IsQuiverVertex( y ) then
							return f( IncomingArrowsOfVertex( y )[1], K-1 );
						else
							return f( SourceOfPath( y ), K-1 );
						fi;
					else
						if IsQuiverVertex( y ) then
							return f( OutgoingArrowsOfVertex( y )[1], K+1 );
						else
							return f( TargetOfPath( y ), K+1 );
						fi;
					fi;
                end;

                return f( x, k );
            fi;
        fi;
    end
);


#########1#########2#########3#########4#########5#########6#########7#########
