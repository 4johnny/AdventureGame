//
//  main.m
//  AdventureGame
//
//  Created by Johnny on 2015-01-17.
//  Copyright (c) 2015 Empath Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>


//
// Macros
//

#if __has_feature(objc_arc)
#define MDLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#else
#define MDLog(format, ...) CFShow([NSString stringWithFormat:format, ## __VA_ARGS__]);
#endif


#define EXIT_FAILURE_GRID_INVALID -1
#define EXIT_FAILURE_TREASURE_NOT_INITIALIZED -2
#define EXIT_FAILURE_CUBE_NOT_INITIALIZED -3
#define EXIT_FAILURE_GEM_NOT_INITIALIZED -4

#define C_QUIT 'q'

#define S_YES "Yes"
#define S_NO "No"

#define S_TREASURE "Treasure"
#define S_CUBE "Cube"
#define S_GEM "Gem"

#define INIT_HEALTH 2
#define CUBE_PENALTY (INIT_HEALTH/2)

// X and Y sizes must be > 0.  At least one of X or Y sizes must be > 1.
#define X_SIZE 4
#define Y_SIZE 4


//
// Types
//

typedef enum GridDirection {
	
	GridDirection_None = '\0',
	GridDirection_North = 'n',
	GridDirection_South = 's',
	GridDirection_West = 'w',
	GridDirection_East = 'e'
	
} GridDirection;


typedef struct Room {
	
	int x;
	int y;
	
	struct Room* northRoom;
	struct Room* southRoom;
	struct Room* westRoom;
	struct Room* eastRoom;
	
	BOOL hasNorthExit;
	BOOL hasSouthExit;
	BOOL hasWestExit;
	BOOL hasEastExit;
	
	BOOL isEmpty;
	BOOL hasTreasure;
	BOOL hasCube;
	BOOL hasGem;
	
} Room;


typedef struct Player {
	
	char* name;
	int health;
	
	Room* currRoom;
	
	BOOL hasTreasure;
	BOOL hasGem;
	
} Player;


//
// Helpers
//

Room* getRoomNeighbour(Room* room, GridDirection direction) {
	
	if (!room) return room;
	
	switch (direction) {
			
		case GridDirection_North:
			return room->northRoom;
			
		case GridDirection_South:
			return room->southRoom;
			
		case GridDirection_West:
			return room->westRoom;
			
		case GridDirection_East:
			return room->eastRoom;
			
		default:
			return room;
	}
}


BOOL setRoomNeighbourNorthSouth(Room* northRoom, Room* southRoom) {
	
	if (!northRoom || !southRoom) return FALSE;
	
	northRoom->southRoom = southRoom;
	southRoom->northRoom = northRoom;
	
	return TRUE;
}


BOOL setRoomNeighbourWestEast(Room* westRoom, Room* eastRoom) {
	
	if (!westRoom || !eastRoom) return FALSE;
	
	westRoom->eastRoom = eastRoom;
	eastRoom->westRoom = westRoom;
	
	return TRUE;
}


BOOL setRoomNeighbour(Room* srcRoom, Room* destRoom, GridDirection direction) {
	
	if (!direction || !srcRoom || !destRoom) return FALSE;
	
	switch (direction) {
			
		case GridDirection_North:
			return setRoomNeighbourNorthSouth(destRoom, srcRoom);
			
		case GridDirection_South:
			return setRoomNeighbourNorthSouth(srcRoom, destRoom);
			
		case GridDirection_West:
			return setRoomNeighbourWestEast(destRoom, srcRoom);
			
		case GridDirection_East:
			return setRoomNeighbourWestEast(srcRoom, destRoom);
			
		default:
			return FALSE;
	}
}


int getGridDimByDirection(Room* room, GridDirection direction) {
	
	if (!room) return 0;
	if (!direction) return 1;

	return 1 + getGridDimByDirection(getRoomNeighbour(room, direction), direction);
}


int getGridDimX(Room* gridOriginRoom) {
	return getGridDimByDirection(gridOriginRoom, GridDirection_East);
}


int getGridDimY(Room* gridOriginRoom) {
	return getGridDimByDirection(gridOriginRoom, GridDirection_North);
}


Room* getGridRoomByDirection(Room* room, GridDirection direction, int index) {
	
	if (!room) return NULL;
	if (index <= 0) return room;
	
	room = getRoomNeighbour(room, direction);
	
	return getGridRoomByDirection(room, direction, index - 1);
}


Room* getGridRoomByIndex(Room* room, int x, int y) {
	
	if (x < 0 || X_SIZE <= x ||
		y < 0 || Y_SIZE <= y) return NULL;
	
	room = getGridRoomByDirection(room, GridDirection_East, x);
	
	return getGridRoomByDirection(room, GridDirection_North, y);
}


//
// Initializers
//

Room* roomInitWithAll(Room* room, int x, int y,
					  Room* northRoom, Room* southRoom, Room* westRoom, Room* eastRoom,
					  BOOL hasNorthExit, BOOL hasSouthExit, BOOL hasWestExit, BOOL hasEastExit,
					  BOOL isEmpty, BOOL hasTreasure, BOOL hasCube, BOOL hasGem) {
	
	room->x = x;
	room->y = y;
	
	room->northRoom = northRoom;
	room->southRoom = southRoom;
	room->westRoom = westRoom;
	room->eastRoom = eastRoom;
	
	room->hasNorthExit = hasNorthExit;
	room->hasSouthExit = hasSouthExit;
	room->hasWestExit = hasWestExit;
	room->hasEastExit = hasEastExit;
	
	room->isEmpty = isEmpty;
	room->hasTreasure = hasTreasure;
	room->hasCube = hasCube;
	room->hasGem = hasGem;
	
	return room;
}


Room* roomInitWithXY(Room* room, int x, int y) {
	return roomInitWithAll(room, x, y,
						   NULL, NULL, NULL, NULL,
						   TRUE, TRUE, TRUE, TRUE,
						   TRUE, FALSE, FALSE, FALSE);
}


Room* createRoom() {
	return malloc(sizeof(Room));
}


void destroyRoom(Room** room) {
	if (!room || !*room) return;
	free(*room);
	*room = NULL;
}


Room* createRoomListX(int xSize, int y, Room* eastRoom, Room* northRoom) {
	
	if (xSize <= 0) return eastRoom;
	
	// Create room and connect to neighbours to east and north, if present.
	Room* room = roomInitWithXY(createRoom(), xSize - 1, y);
	setRoomNeighbour(room, eastRoom, GridDirection_East);
	setRoomNeighbour(room, northRoom, GridDirection_North);

	if (northRoom) northRoom = northRoom->westRoom;
	
	return createRoomListX(xSize - 1, y, room, northRoom);
}


Room* createRoomListY(int x, int ySize, Room* northRoom) {
	
	if (ySize <= 0) return northRoom;

	northRoom = getGridRoomByDirection(northRoom, GridDirection_East, x - 1);
	
	Room* room = createRoomListX(x, ySize - 1, NULL, northRoom);
	
	return createRoomListY(x, ySize - 1, room);
}


Room* createRoomGrid(int xSize, int ySize) {
	
	if (xSize < 1 || ySize < 1) return NULL;
	if (xSize == 1 && ySize == 1) return NULL;
	
	return createRoomListY(xSize, ySize, NULL);
}


void destroyRoomGrid(Room** gridOriginRoom) {
	// TODO: Free up memory.  Consider keeping a global list of all created rooms.  Then just traverse list to "garbage collect".
}


Player* initPlayer(Player* player, char* name, int health, Room* room) {
	
	player->name = malloc(strlen(name) + 1);
	strcpy(player->name, name);
	
	player->health = health;
	player->currRoom = room;
	
	player->hasTreasure = FALSE;
	player->hasGem = FALSE;
	
	return player;
}


//
// Game logic
//


BOOL isOrigin(int x, int y) {
	return x == 0 && y == 0;
}


Room* placeThingRandom(Room* gridOriginRoom, char* thingName) {
	
	if (!gridOriginRoom || !thingName) return NULL;
	
	Room* room = gridOriginRoom;
	int xDim = getGridDimX(room);
	int yDim = getGridDimY(room);

	while (TRUE) {

		// Get random coordinate. If origin, try again.
		int x = arc4random_uniform(xDim);
		int y = arc4random_uniform(yDim);
		if (isOrigin(x, y)) continue;
		
		// Get room at coordinate.
		room = getGridRoomByIndex(room, x, y);
		if (!room) {
			MDLog(@"Cannot place %s.", thingName);
			return NULL;
		}

		// Place thing.
		if (strcmp(thingName, "Treasure") == 0) {
			room->hasTreasure = TRUE;
		} else if (strcmp(thingName, "Cube") == 0) {
			room->hasCube = TRUE;
		} else if (strcmp(thingName, "Gem") == 0) {
			room->hasGem = TRUE;
		}
		MDLog(@"%s: (%d,%d)", thingName, x, y);
		break;
	}
	
	return room;
}


void showPlayerStatus(Player* player) {
	
	Room* room = player->currRoom;
	MDLog(@"%s's Status: Health:%.0f%% | Gem:%s | Room:(%d,%d)",
		  player->name,
		  ((float)player->health / INIT_HEALTH) * 100,
		  player->hasGem ? S_YES : S_NO,
		  room->x, room->y);
	
	MDLog(@"Exits:");
	if (room->northRoom) MDLog(@"\tNorth");
	if (room->southRoom) MDLog(@"\tSouth");
	if (room->westRoom) MDLog(@"\tWest");
	if (room->eastRoom) MDLog(@"\tEast");
	//	if (room->hasNorthExit) MDLog(@"\tNorth");
	//	if (room->hasSouthExit) MDLog(@"\tSouth");
	//	if (room->hasWestExit) MDLog(@"\tWest");
	//	if (room->hasEastExit) MDLog(@"\tEast");
}


BOOL tryMoveDirection(Room* gridOriginRoom, Player* player, Room* nextRoom, Room* checkRoom, BOOL exit) {
	
	// If next room is not valid, we are done.
	if (!checkRoom || nextRoom != checkRoom || !exit) return FALSE;
	
	// Move player to next room, and run game rules.
	player->currRoom = nextRoom;
	
	// If treasure, grab it.
	if (checkRoom->hasTreasure) {
		checkRoom->hasTreasure = FALSE;
		player->hasTreasure = TRUE;
		MDLog(@"Found %s!", S_TREASURE);
	}
	
	// If gem, grab it.
	if (checkRoom->hasGem) {
		checkRoom->hasGem = FALSE;
		player->hasGem = TRUE;
		MDLog(@"Found %s!", S_GEM);
	}
	
	// If cube, destroy with gem; o/w get injured and cube moves.
	if (checkRoom->hasCube && !player->hasTreasure) {
		if (player->hasGem) {
			player->hasGem = FALSE;
			checkRoom->hasCube = FALSE;
			MDLog(@"Destroyed %s with %s!", S_CUBE, S_GEM);
		} else {
			player->health -= CUBE_PENALTY;
			MDLog(@"Injured by %s!", S_CUBE);
			checkRoom->hasCube = FALSE;
			if (!placeThingRandom(gridOriginRoom, S_CUBE)) {
				checkRoom->hasCube = TRUE;
			}
		}
	}
	
	return TRUE; // Move was valid
}


BOOL tryMove(Room* gridOriginRoom, Player* player, Room* nextRoom) {
	
	Room* currRoom = player->currRoom;
	
	// Try to move player to desired direction. Check all directions.
	if (tryMoveDirection(gridOriginRoom, player, nextRoom, currRoom->northRoom, currRoom->hasNorthExit)) return TRUE;
	if (tryMoveDirection(gridOriginRoom, player, nextRoom, currRoom->southRoom, currRoom->hasSouthExit)) return TRUE;
	if (tryMoveDirection(gridOriginRoom, player, nextRoom, currRoom->westRoom, currRoom->hasWestExit)) return TRUE;
	if (tryMoveDirection(gridOriginRoom, player, nextRoom, currRoom->eastRoom, currRoom->hasEastExit)) return TRUE;
	
	return FALSE;
}


//
// Main
//

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		
		// Reusable input buffer.
		char str[255];
		
		// Config room grid.
		// Add treasure, cube, & gem at random spots (not origin).
		Room* gridOriginRoom = createRoomGrid(X_SIZE, Y_SIZE);
		if (!gridOriginRoom) {
			MDLog(@"Invalid room grid.");
			return EXIT_FAILURE_GRID_INVALID;
		}
		MDLog(@"Grid: (%d,%d)", getGridDimX(gridOriginRoom), getGridDimY(gridOriginRoom));
		if (!placeThingRandom(gridOriginRoom, S_TREASURE)) return EXIT_FAILURE_TREASURE_NOT_INITIALIZED;
		if (!placeThingRandom(gridOriginRoom, S_CUBE)) return EXIT_FAILURE_CUBE_NOT_INITIALIZED;
		if (!placeThingRandom(gridOriginRoom, S_GEM)) return EXIT_FAILURE_GEM_NOT_INITIALIZED;
		
		// Config player.
		MDLog(@"Player name: ");
		MDLog(@"> "); scanf("%s", str);
		Player player; initPlayer(&player, str, INIT_HEALTH, gridOriginRoom);
		
		// Play game until quit.
		Room* nextRoom = NULL;
		BOOL isGameOn = TRUE;
		while (isGameOn) { // REPL
			
			// Check player status.
			// If player has treasure, they win game.
			// If player has no health, game is over.
			showPlayerStatus(&player);
			if (player.hasTreasure) {
				MDLog(@"%s WINS!", player.name);
				isGameOn = FALSE;
			} else if (player.health <= 0) {
				MDLog(@"%s LOSES!", player.name);
				isGameOn = FALSE;
			}
			if (!isGameOn) break;
			
			// Ask player for direction, until valid.
			// If quit, we are done.
			while (TRUE) {
				
				// Ask player for direction.
				MDLog(@"Direction (%c,%c,%c,%c,%c)? ",
					  GridDirection_North, GridDirection_South,
					  GridDirection_West, GridDirection_East,
					  C_QUIT);
				MDLog(@"> "); scanf("%s", str);
				if (str[0] == C_QUIT) {
					isGameOn = FALSE;
					break;
				}
				
				// Validate direction.
				GridDirection direction = (GridDirection)str[0];
				nextRoom = getRoomNeighbour(player.currRoom, direction);
				if (nextRoom == player.currRoom) {
					MDLog(@"Invalid direction request.");
					continue;
				}
				
				// Try to move player in requested direction.
				if (tryMove(gridOriginRoom, &player, nextRoom)) break;

				MDLog(@"Unable to move in direction: %c", direction);
			}
			
		} // REPL
		
	} // @autoreleasepool

	return EXIT_SUCCESS;
}
