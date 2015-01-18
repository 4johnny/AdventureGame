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

#define QUIT_CHAR 'q'

// X & Y sizes must be > 0.  One of X or Y sizes must be > 1.
#define X_SIZE 3
#define Y_SIZE 1 // TODO: Implement Y > 1

#define INIT_HEALTH 2
#define CUBE_PENALTY (INIT_HEALTH/2)


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


Player* initPlayer(Player* player, char* name, int health, Room* room) {
	
	player->name = malloc(strlen(name) + 1);
	strcpy(player->name, name);
	
	player->health = health;
	player->currRoom = room;
	
	player->hasTreasure = FALSE;
	player->hasGem = FALSE;
	
	return player;
}


Room* connectRoomToEastList(Room* room, Room* eastList) {
	
	if (!room) return NULL;
	
	if (eastList) {
		eastList->westRoom = room;
	}
	
	room->eastRoom = eastList;
	
	return room;
}


Room* createRoomListX(int xSize, int y, Room* eastList, Room* northList) {
	
	if (xSize <= 0) return eastList;
	
	Room* room = roomInitWithXY(createRoom(), xSize - 1, y);
	room = connectRoomToEastList(room, eastList);
	
	room = createRoomListX(xSize - 1, y, room, northList);
	
	return room;
}


Room* createRoomListY(int x, int ySize, Room* northList) {
	
	if (ySize <= 0) return northList;

	if (northList) {
		northList = getGridRoomByDirection(northList, GridDirection_East, x - 1);
	}

	Room* room = createRoomListX(x, ySize - 1, NULL, northList);
	room = createRoomListY(x, ySize - 1, room);
	
	return room;
}


Room* createRoomGrid(int xSize, int ySize) {
	
	if (xSize <= 1 && ySize <= 1) return NULL;
	
	return createRoomListY(xSize, ySize, NULL);
}


void destroyRoomGrid(Room** gridOriginRoom) {
	// TODO: Free up memory.  Consider keeping a global list of all created rooms.  Then just traverse list to "garbage collect".
}


//
// Game logic
//


BOOL isOrigin(int x, int y) {
	return x == 0 && y == 0;
}


Room* initTreasure(Room* room, int xSize, int ySize) {

	while (TRUE) {
	
		// Get random coordinate (not origin).
		int x = arc4random_uniform(xSize);
		int y = arc4random_uniform(ySize);
		if (isOrigin(x, y)) continue;

		// Get room at coordinate.
		room = getGridRoomByIndex(room, x, y);
		if (!room) return NULL;
		room->hasTreasure = TRUE;
		break;
	}

	return room;
}

void showPlayerStatus(Player* player) {
	
	MDLog(@"%s's Status:", player->name);
	MDLog(@"Health: %d/%d", player->health, INIT_HEALTH);
	
	Room* room = player->currRoom;
	MDLog(@"Room: (%d,%d)", room->x, room->y);
	
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


BOOL tryMoveDirection(Player* player, Room* nextRoom, Room* checkRoom, BOOL exit) {
	
	// If next room is not valid, we are done.
	if (!checkRoom || nextRoom != checkRoom || !exit) return FALSE;
	
	// Move player to next room, and run game rules.
	player->currRoom = nextRoom;
	
	if (checkRoom->hasTreasure) {
		checkRoom->hasTreasure = FALSE;
		player->hasTreasure = TRUE;
		MDLog(@"Found treasure!");
	}
	
	if (checkRoom->hasGem) {
		checkRoom->hasGem = FALSE;
		player->hasGem = TRUE;
		MDLog(@"Found gem!");
	}
	
	if (checkRoom->hasCube && !player->hasTreasure) {
		player->health -= CUBE_PENALTY;
		MDLog(@"Injured by cube!");
	}
	
	return TRUE; // Move was valid
}


BOOL tryMove(Player* player, Room* nextRoom) {
	Room* currRoom = player->currRoom;
	
	// If next room player desires is possible, move player.
	// Check all directions.
	if (tryMoveDirection(player, nextRoom, currRoom->northRoom, currRoom->hasNorthExit)) return TRUE;
	if (tryMoveDirection(player, nextRoom, currRoom->southRoom, currRoom->hasSouthExit)) return TRUE;
	if (tryMoveDirection(player, nextRoom, currRoom->westRoom, currRoom->hasWestExit)) return TRUE;
	if (tryMoveDirection(player, nextRoom, currRoom->eastRoom, currRoom->hasEastExit)) return TRUE;
	
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
		// Add treasure at ramdom spot (not origin).
		Room* gridOriginRoom = createRoomGrid(X_SIZE, Y_SIZE);
		if (!gridOriginRoom) {
			MDLog(@"Invalid room grid.");
			return EXIT_FAILURE_GRID_INVALID;
		}
		if (!initTreasure(gridOriginRoom, X_SIZE, Y_SIZE)) {
			MDLog(@"Cannot place treasure.");
			return EXIT_FAILURE_TREASURE_NOT_INITIALIZED;
		}
		
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
				MDLog(@"Direction (%c,%c,%c,%c,%c): ",
					  GridDirection_North, GridDirection_South,
					  GridDirection_West, GridDirection_East,
					  QUIT_CHAR);
				MDLog(@"> "); scanf("%s", str);
				if (str[0] == QUIT_CHAR) {
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
				
				// Move player in requested direction, if possible.
				if (tryMove(&player, nextRoom)) {
					MDLog(@"Moved successfully in direction: %c", direction);
					break;
				}

				MDLog(@"Unable to move in direction: %c", direction);
			}
			
		} // REPL
		
	} // @autoreleasepool

	return EXIT_SUCCESS;
}
