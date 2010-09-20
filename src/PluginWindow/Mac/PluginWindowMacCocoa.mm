/**********************************************************\
Original Author: Anson MacKeracher 

Created:    Mar 26, 2010
License:    Dual license model; choose one of two:
            New BSD License
            http://www.opensource.org/licenses/bsd-license.php
            - or -
            GNU Lesser General Public License, version 2.1
            http://www.gnu.org/licenses/lgpl-2.1.html

Copyright 2010 Anson MacKeracher, Firebreath development team
\**********************************************************/

#include "PluginWindowMacCocoa.h"
#include <Foundation/NSString.h>

using namespace FB; using namespace std;

PluginWindowMacCocoa::PluginWindowMacCocoa() {}

PluginWindowMacCocoa::~PluginWindowMacCocoa() {}

/*
char mapCharacter(char character) {
    switch(character) {
    case 18:
        return '1';    
    case 19:
        return '2';
    case 20:
        return '3';
    case 21:
        return '4';
    case 23:
        return '5';
    case 22:
        return '6';
    case 26:
        return '7';
    case 28:
        return '8';
    case 25:
        return '9';
    case 29:
        return '0';
    case 27:
        return '-';
    case 24:
        return '+';
    case 44:
        return '/';
    case 36: 
        // enter
        return 0xd;
    case 51:
        // backspace
        return 0x08;
    case 123:
        return 0x1c;
    case 124:
        return 0x1d;
    default: 
        return 0;
    }
}
*/

int16_t PluginWindowMacCocoa::HandleEvent(NPCocoaEvent* evt) {
    // Let the plugin handle the event if it wants
    MacEventCocoa* macEv = new MacEventCocoa(evt);
    if(SendEvent(macEv)) {
        return true;
    }

    // Otherwise process the event into FB platform agnostic events
    switch(evt->type) {
        case NPCocoaEventDrawRect: {
            // TODO
            break;
        }

        case NPCocoaEventMouseDown: {
            double x = evt->data.mouse.pluginX;
            double y = evt->data.mouse.pluginY;
            y = m_height - y; // Reposition origin to bottom left
            switch(evt->data.mouse.buttonNumber) {
                case 0: {
                    MouseDownEvent ev(MouseButtonEvent::MouseButton_Left, x, y);
                    return SendEvent(&ev);
                    break;
                }
                case 1: {
                    MouseDownEvent ev(MouseButtonEvent::MouseButton_Right, x, y);
                    return SendEvent(&ev);
                    break;
                }
                case 2: {
                    MouseDownEvent ev(MouseButtonEvent::MouseButton_Middle, x, y);
                    return SendEvent(&ev);
                    break;
                }
            }
        }

        case NPCocoaEventMouseUp: {
            double x = evt->data.mouse.pluginX;
            double y = evt->data.mouse.pluginY;
            y = m_height - y; // Reposition origin to bottom left
            switch(evt->data.mouse.buttonNumber) {
                case 0: {
                    MouseUpEvent ev(MouseButtonEvent::MouseButton_Left, x, y);
                    return SendEvent(&ev);
                    break;
                }
                case 1: {
                    MouseUpEvent ev(MouseButtonEvent::MouseButton_Right, x, y);
                    return SendEvent(&ev);
                    break;
                }
                case 2: {
                    MouseUpEvent ev(MouseButtonEvent::MouseButton_Middle, x, y);
                    return SendEvent(&ev);
                    break;
                }
            }
        }

        case NPCocoaEventMouseMoved: {
            double x = evt->data.mouse.pluginX;
            double y = evt->data.mouse.pluginY;
            y = m_height - y; // Reposition origin to bottom left
            MouseMoveEvent ev(x, y);
            return SendEvent(&ev);
            break;
        }

        case NPCocoaEventMouseEntered: {
            break;

        }

        case NPCocoaEventMouseExited: {
            break;
        }

        case NPCocoaEventMouseDragged: {
            double x = evt->data.mouse.pluginX;
            double y = evt->data.mouse.pluginY;
            y = m_height - y; // Reposition origin to bottom left
            MouseMoveEvent ev(x, y);
            return SendEvent(&ev);
            break;
        }

        case NPCocoaEventKeyDown: {
            int key = (int)evt->data.key.keyCode;
            NSString* str = (NSString *)evt->data.key.characters;
            char character = [str characterAtIndex:0];
            KeyDownEvent ev(CocoaKeyCodeToFBKeyCode(key), character);
            bool rtn = SendEvent(&ev);
            return rtn;
            break;
        }

        case NPCocoaEventKeyUp: {
            int key = (int)evt->data.key.keyCode;
            //char character = mapCharacter(key);
            KeyUpEvent ev(CocoaKeyCodeToFBKeyCode(key), key);
            return SendEvent(&ev);
            break;
        }

        case NPCocoaEventFlagsChanged: {
            break;
        }

        case NPCocoaEventFocusChanged: {
            FocusChangedEvent ev(evt->data.focus.hasFocus);
            return SendEvent(&ev);
            break;
        }

        case NPCocoaEventWindowFocusChanged: {
            // Not handled
            break;
        }

        case NPCocoaEventScrollWheel: {
            break;
        }

        case NPCocoaEventTextInput: {
            // Not handled
            break;
        }
    }

    // Event was not handled by the plugin
    return false;
}

NPRect PluginWindowMacCocoa::getWindowPosition() {
    NPRect r = { m_y, m_x, m_y + m_height, m_x + m_width };
    return r;
}

NPRect PluginWindowMacCocoa::getWindowClipping() {
    NPRect r = { m_clipTop, m_clipLeft, m_clipBottom, m_clipRight };
    return r;
}

int PluginWindowMacCocoa::getWindowHeight() {
    return m_height;
}

int PluginWindowMacCocoa::getWindowWidth() {
    return m_width;
}

void PluginWindowMacCocoa::setWindowPosition(int32_t x, int32_t y, int32_t width, int32_t height) {
    m_x = x;
    m_y = y;
    m_width = width;
    m_height = height;
}

void PluginWindowMacCocoa::setWindowClipping(uint16_t top, uint16_t left, uint16_t bottom, uint16_t right) {
    m_clipTop = top;
    m_clipLeft = left;
    m_clipBottom = bottom;
    m_clipRight = right;
}

void FB::timerCallback(NPP npp, uint32_t timerID) {
    FB::Npapi::NpapiPlugin* p = FB::Npapi::getPlugin(npp);
    FB::Npapi::NpapiPluginMac* plugin = dynamic_cast<FB::Npapi::NpapiPluginMac*>(p);
    if(plugin != NULL) {
        plugin->HandleCocoaTimerEvent();
    }
}

int PluginWindowMacCocoa::scheduleTimer(int interval, bool repeat) {
    if(m_npHost != NULL) {
        return m_npHost->ScheduleTimer(interval, repeat, timerCallback);
    } else {
        return 0;
    }
}

void PluginWindowMacCocoa::unscheduleTimer(int timerId) {
    if(m_npHost != NULL) {
        m_npHost->UnscheduleTimer(timerId);
    } 
}

void PluginWindowMacCocoa::InvalidateWindow() {
    //NPRect rect = { m_clipTop, m_clipLeft, m_clipBottom, m_clipRight };
    NPRect rect = { m_y, m_x, m_y + m_height, m_x + m_width };
    m_npHost->InvalidateRect(&rect);
}

void PluginWindowMacCocoa::handleTimerEvent() {
    TimerEvent ev(0, NULL);
    SendEvent(&ev);
}
