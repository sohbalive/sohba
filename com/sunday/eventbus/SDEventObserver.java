package com.sunday.eventbus;

public interface SDEventObserver
{
	public void onEventMainThread(SDBaseEvent event);
}
