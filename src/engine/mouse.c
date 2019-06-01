typedef struct {
    int32_t x;
    int32_t y;
    bool left;
    bool middle;
    bool right;
} MOUSE;

void MOUSE_getX(WrenVM* vm) {
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  wrenSetSlotDouble(vm, 0, mouse->x);
}

void MOUSE_getY(WrenVM* vm) {
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  wrenSetSlotDouble(vm, 0, mouse->y);
}

void MOUSE_getLeft(WrenVM* vm) {
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  wrenSetSlotBool(vm, 0, mouse->left);
}

void MOUSE_getMiddle(WrenVM* vm) {
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  wrenSetSlotBool(vm, 0, mouse->middle);
}

void MOUSE_getRight(WrenVM* vm) {
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  wrenSetSlotBool(vm, 0, mouse->right);
}

void MOUSE_update(WrenVM* vm) {
  ENGINE* engine = (ENGINE*)wrenGetUserData(vm);
  MOUSE* mouse = (MOUSE*)wrenGetSlotForeign(vm, 0);
  ENGINE_getMouseState(engine, &(mouse->x), &(mouse->y), &(mouse->left), &(mouse->middle), &(mouse->right));
}

